import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/auth_token_store.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/chat_connection_status.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_realtime_event.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_model.dart';

/// Socket.io implementation of [ChatRepository]. Authenticates the handshake
/// with the stored JWT, maps server events into the domain [ChatRealtimeEvent]
/// stream, and exposes ack-based request/response for join & send.
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._tokenStore);

  final AuthTokenStore _tokenStore;
  final StreamController<ChatRealtimeEvent> _events =
      StreamController<ChatRealtimeEvent>.broadcast();

  io.Socket? _socket;
  String _currentUserId = '';

  static const Duration _ackTimeout = Duration(seconds: 12);

  @override
  Stream<ChatRealtimeEvent> get events => _events.stream;

  @override
  Future<void> connect(String currentUserId) async {
    _currentUserId = currentUserId;
    await disconnect();

    final token = await _tokenStore.readToken() ?? '';
    final socket = io.io(
      ApiEndpoints.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/socket.io')
          // Backend handshake auth reads the Authorization header (and auth.token);
          // headers are the broadly-supported path on the mobile IO transport.
          .setExtraHeaders(<String, dynamic>{'Authorization': 'Bearer $token'})
          .setAuth(<String, dynamic>{'token': token})
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );
    _socket = socket;
    _registerHandlers(socket);

    final connected = Completer<void>();
    socket.onConnect((_) {
      _events.add(const ConnectionStateEvent(ChatConnectionStatus.connected));
      if (!connected.isCompleted) connected.complete();
    });
    socket.onConnectError((Object? _) {
      _events.add(const ConnectionStateEvent(ChatConnectionStatus.error));
      if (!connected.isCompleted) {
        connected.completeError(const ChatException('Unable to reach chat service.'));
      }
    });

    socket.connect();
    return connected.future.timeout(
      _ackTimeout,
      onTimeout: () => throw const ChatException('Chat connection timed out.'),
    );
  }

  void _registerHandlers(io.Socket socket) {
    socket
      ..on('chat:message', (Object? data) {
        final map = _asMap(data);
        if (map != null) {
          _events.add(
            IncomingMessageEvent(ChatMessageModel.fromDto(map, _currentUserId)),
          );
        }
      })
      ..on('chat:read', (Object? data) {
        final map = _asMap(data);
        if (map == null) return;
        final ids = (map['messageIds'] as List?)
                ?.map((e) => e.toString())
                .toList(growable: false) ??
            const <String>[];
        _events.add(ReadReceiptEvent(by: (map['by'] ?? '').toString(), messageIds: ids));
      })
      ..on('chat:typing', (Object? data) {
        final map = _asMap(data);
        if (map == null) return;
        _events.add(TypingEvent(
          userId: (map['userId'] ?? '').toString(),
          isTyping: map['isTyping'] == true,
        ));
      })
      ..on('chat:presence', (Object? data) {
        final map = _asMap(data);
        if (map == null) return;
        _events.add(PresenceEvent(
          userId: (map['userId'] ?? '').toString(),
          online: map['online'] == true,
        ));
      })
      ..on('chat:error', (Object? data) {
        final map = _asMap(data);
        _events.add(ChatErrorEvent((map?['message'] ?? 'Chat error.').toString()));
      })
      ..onDisconnect((_) {
        _events.add(const ConnectionStateEvent(ChatConnectionStatus.disconnected));
      });
  }

  @override
  Future<List<ChatMessage>> joinRoom(String appointmentId) async {
    final data = await _emitWithAck('chat:join', {'appointmentId': appointmentId});
    final history = (data['history'] as List?) ?? const [];
    return history
        .map((e) => ChatMessageModel.fromDto(_asMap(e) ?? const {}, _currentUserId))
        .toList(growable: false);
  }

  @override
  Future<ChatMessage> sendMessage({
    required String appointmentId,
    required String body,
  }) async {
    final data = await _emitWithAck('chat:send', {
      'appointmentId': appointmentId,
      'body': body,
    });
    return ChatMessageModel.fromDto(data, _currentUserId);
  }

  @override
  Future<void> markRead(String appointmentId, {List<String>? messageIds}) async {
    _socket?.emit('chat:read', {
      'appointmentId': appointmentId,
      if (messageIds != null) 'messageIds': messageIds,
    });
  }

  @override
  void sendTyping(String appointmentId, {required bool isTyping}) {
    _socket?.emit('chat:typing', {
      'appointmentId': appointmentId,
      'isTyping': isTyping,
    });
  }

  @override
  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null;
    socket?.dispose();
  }

  Future<DataMap> _emitWithAck(String event, DataMap payload) {
    final socket = _socket;
    if (socket == null) {
      throw const ChatException('Not connected to chat.');
    }
    final completer = Completer<DataMap>();
    socket.emitWithAck(
      event,
      payload,
      ack: (Object? response) {
        final map = _asMap(response);
        if (map == null) {
          completer.completeError(const ChatException('Malformed chat response.'));
          return;
        }
        if (map['ok'] == true) {
          completer.complete(_asMap(map['data']) ?? <String, dynamic>{});
        } else {
          completer.completeError(
            ChatException((map['error'] ?? 'Chat request failed.').toString()),
          );
        }
      },
    );
    return completer.future.timeout(
      _ackTimeout,
      onTimeout: () => throw const ChatException('Chat request timed out.'),
    );
  }

  DataMap? _asMap(Object? data) {
    if (data is Map) return data.cast<String, dynamic>();
    // Some ack transports wrap the response in a single-element list.
    if (data is List && data.isNotEmpty && data.first is Map) {
      return (data.first as Map).cast<String, dynamic>();
    }
    return null;
  }
}
