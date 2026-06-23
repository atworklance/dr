import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/auth_token_store.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/call_signal_event.dart';
import '../../domain/entities/incoming_call.dart';
import '../../domain/entities/watchable_appointment.dart';
import '../../domain/repositories/call_signaling_repository.dart';

/// Realtime + REST implementation of [CallSignalingRepository]. Fetches the
/// provider's confirmed appointments via the API, joins their rooms over the
/// socket, and maps `call:incoming` / `call:ended` into domain events.
class CallSignalingRepositoryImpl implements CallSignalingRepository {
  CallSignalingRepositoryImpl({
    required ApiClient client,
    required AuthTokenStore tokenStore,
  })  : _client = client,
        _tokenStore = tokenStore;

  final ApiClient _client;
  final AuthTokenStore _tokenStore;

  final StreamController<CallSignalEvent> _events =
      StreamController<CallSignalEvent>.broadcast();
  final Map<String, WatchableAppointment> _watched = {};

  io.Socket? _socket;

  @override
  Stream<CallSignalEvent> get events => _events.stream;

  @override
  Future<List<WatchableAppointment>> fetchWatchableAppointments() async {
    final response = await _client.get(
      ApiEndpoints.appointments,
      queryParameters: <String, dynamic>{'status': 'confirmed', 'limit': 100},
    );
    final list = (response['data'] as List?) ?? const [];
    return list.whereType<Map>().map((raw) {
      final dto = raw.cast<String, dynamic>();
      final session = (dto['session'] as Map?)?.cast<String, dynamic>();
      final window = (dto['timeWindow'] as Map?)?.cast<String, dynamic>();
      return WatchableAppointment(
        id: (dto['id'] ?? dto['_id'] ?? '').toString(),
        channelName: session?['videoChannelName'] as String?,
        startsAt: DateTime.tryParse(window?['start'] as String? ?? '')?.toLocal(),
      );
    }).toList();
  }

  @override
  Future<void> connect(String currentUserId) async {
    await dispose();
    final token = await _tokenStore.readToken() ?? '';
    final socket = io.io(
      ApiEndpoints.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/socket.io')
          .setExtraHeaders(<String, dynamic>{'Authorization': 'Bearer $token'})
          .setAuth(<String, dynamic>{'token': token})
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );
    _socket = socket;

    socket
      ..on('call:incoming', (Object? data) {
        final map = _asMap(data);
        if (map == null) return;
        final channel = (map['channel'] ?? '').toString();
        final appointmentId = _appointmentIdFromChannel(channel);
        final watched = _watched[appointmentId];
        _events.add(
          IncomingCallReceived(
            IncomingCall(
              appointmentId: appointmentId,
              channelName: channel,
              callerId: (map['by'] ?? '').toString(),
              receivedAt: DateTime.now(),
              startsAt: watched?.startsAt,
            ),
          ),
        );
      })
      ..on('call:ended', (_) => _events.add(const CallCancelled()))
      ..onDisconnect(
        (_) => _events.add(const CallSignalConnection(connected: false)),
      );

    final connected = Completer<void>();
    socket.onConnect((_) {
      _events.add(const CallSignalConnection(connected: true));
      if (!connected.isCompleted) connected.complete();
    });
    socket.onConnectError((Object? _) {
      if (!connected.isCompleted) connected.complete();
    });
    socket.connect();
    await connected.future
        .timeout(const Duration(seconds: 12), onTimeout: () {});
  }

  @override
  Future<void> watch(List<WatchableAppointment> appointments) async {
    final socket = _socket;
    if (socket == null) return;
    for (final appointment in appointments) {
      _watched[appointment.id] = appointment;
      socket.emit('chat:join', {'appointmentId': appointment.id});
    }
  }

  @override
  Future<void> dispose() async {
    final socket = _socket;
    _socket = null;
    socket?.dispose();
  }

  String _appointmentIdFromChannel(String channel) =>
      channel.startsWith('vch_') ? channel.substring(4) : channel;

  DataMap? _asMap(Object? data) {
    if (data is Map) return data.cast<String, dynamic>();
    if (data is List && data.isNotEmpty && data.first is Map) {
      return (data.first as Map).cast<String, dynamic>();
    }
    return null;
  }
}
