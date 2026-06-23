import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chat_connection_status.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_realtime_event.dart';
import '../../domain/repositories/chat_repository.dart';

part 'chat_state.dart';

/// Drives an appointment conversation: connects the socket, loads history,
/// streams realtime events, and renders optimistic outgoing messages that are
/// reconciled against the server (with delivery/read receipts).
class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required ChatRepository repository,
    required String appointmentId,
    required String currentUserId,
  })  : _repository = repository,
        _appointmentId = appointmentId,
        _currentUserId = currentUserId,
        super(const ChatState());

  final ChatRepository _repository;
  final String _appointmentId;
  final String _currentUserId;

  StreamSubscription<ChatRealtimeEvent>? _subscription;
  Timer? _typingTimer;

  /// Connects, subscribes to realtime events, loads history, and marks the
  /// peer's messages read.
  Future<void> initialize() async {
    emit(state.copyWith(
      connection: ChatConnectionStatus.connecting,
      clearError: true,
    ));
    _subscription = _repository.events.listen(_onEvent);

    try {
      await _repository.connect(_currentUserId);
      final history = await _repository.joinRoom(_appointmentId);
      if (isClosed) return;
      emit(state.copyWith(
        connection: ChatConnectionStatus.connected,
        messages: _sorted(history),
        historyLoaded: true,
        clearError: true,
      ));
      await _repository.markRead(_appointmentId);
    } on ChatException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          connection: ChatConnectionStatus.error,
          errorMessage: e.message,
        ));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          connection: ChatConnectionStatus.error,
          errorMessage: 'Could not open the conversation.',
        ));
      }
    }
  }

  void _onEvent(ChatRealtimeEvent event) {
    if (isClosed) return;
    switch (event) {
      case IncomingMessageEvent(:final message):
        _upsert(message);
        if (!message.isMine) {
          unawaited(_repository.markRead(_appointmentId));
        }
      case ReadReceiptEvent(:final by, :final messageIds):
        if (by != _currentUserId) _applyReadReceipts(messageIds);
      case TypingEvent(:final userId, :final isTyping):
        if (userId != _currentUserId) emit(state.copyWith(isPeerTyping: isTyping));
      case PresenceEvent(:final userId, :final online):
        if (userId != _currentUserId) emit(state.copyWith(isPeerOnline: online));
      case ConnectionStateEvent(:final status):
        emit(state.copyWith(connection: status));
      case ChatErrorEvent(:final message):
        emit(state.copyWith(errorMessage: message));
    }
  }

  /// Optimistically appends the message, then reconciles with the server result.
  Future<void> sendMessage(String text) async {
    final body = text.trim();
    if (body.isEmpty) return;

    final tempId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    _append(
      ChatMessage(
        id: tempId,
        appointmentId: _appointmentId,
        senderId: _currentUserId,
        body: body,
        isMine: true,
        status: MessageDeliveryStatus.sending,
        createdAt: DateTime.now(),
        isOptimistic: true,
      ),
    );

    try {
      final saved = await _repository.sendMessage(
        appointmentId: _appointmentId,
        body: body,
      );
      if (!isClosed) _reconcile(tempId, saved);
    } catch (_) {
      if (!isClosed) _markFailed(tempId);
    }
  }

  /// Re-sends a previously failed message.
  Future<void> retry(ChatMessage failed) async {
    _removeById(failed.id);
    await sendMessage(failed.body);
  }

  /// Broadcasts that the user is typing; auto-clears after a short idle.
  void notifyTyping() {
    _repository.sendTyping(_appointmentId, isTyping: true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _repository.sendTyping(_appointmentId, isTyping: false);
    });
  }

  // --- list maintenance ----------------------------------------------------

  List<ChatMessage> _sorted(List<ChatMessage> items) =>
      [...items]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  void _append(ChatMessage message) {
    emit(state.copyWith(messages: _sorted([...state.messages, message])));
  }

  void _upsert(ChatMessage incoming) {
    final list = [...state.messages];
    final index = list.indexWhere((m) => m.id == incoming.id);
    if (index >= 0) {
      list[index] = _merge(list[index], incoming);
    } else {
      list.add(incoming);
    }
    emit(state.copyWith(messages: _sorted(list)));
  }

  void _reconcile(String tempId, ChatMessage saved) {
    final list = [...state.messages]..removeWhere((m) => m.id == tempId);
    final index = list.indexWhere((m) => m.id == saved.id);
    if (index >= 0) {
      list[index] = _merge(list[index], saved);
    } else {
      list.add(saved);
    }
    emit(state.copyWith(messages: _sorted(list)));
  }

  void _markFailed(String tempId) {
    final list = [...state.messages];
    final index = list.indexWhere((m) => m.id == tempId);
    if (index < 0) return;
    list[index] = list[index].copyWith(status: MessageDeliveryStatus.failed);
    emit(state.copyWith(messages: list));
  }

  void _removeById(String id) {
    emit(state.copyWith(
      messages: state.messages.where((m) => m.id != id).toList(),
    ));
  }

  void _applyReadReceipts(List<String> ids) {
    final idSet = ids.toSet();
    final now = DateTime.now();
    final list = state.messages.map((m) {
      final matches = m.isMine && (idSet.isEmpty || idSet.contains(m.id));
      if (!matches || m.readAt != null) return m;
      return m.copyWith(status: MessageDeliveryStatus.read, readAt: now);
    }).toList();
    emit(state.copyWith(messages: list));
  }

  /// Merges receipt data, preferring the strongest known delivery status.
  ChatMessage _merge(ChatMessage current, ChatMessage incoming) {
    final deliveredAt = incoming.deliveredAt ?? current.deliveredAt;
    final readAt = incoming.readAt ?? current.readAt;
    final MessageDeliveryStatus status;
    if (incoming.isMine) {
      status = readAt != null
          ? MessageDeliveryStatus.read
          : (deliveredAt != null
              ? MessageDeliveryStatus.delivered
              : incoming.status);
    } else {
      status = incoming.status;
    }
    return incoming.copyWith(
      status: status,
      deliveredAt: deliveredAt,
      readAt: readAt,
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _typingTimer?.cancel();
    await _repository.disconnect();
    return super.close();
  }
}
