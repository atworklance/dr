import '../entities/chat_message.dart';
import '../entities/chat_realtime_event.dart';

/// Domain contract for the realtime chat transport. The implementation wraps the
/// Socket.io connection; the presentation layer consumes the [events] stream and
/// drives the imperative methods. Methods throw [ChatException] on failure.
abstract interface class ChatRepository {
  /// Broadcast stream of inbound realtime events.
  Stream<ChatRealtimeEvent> get events;

  /// Establishes the authenticated socket connection. [currentUserId] is used to
  /// resolve message ownership for receipts.
  Future<void> connect(String currentUserId);

  /// Tears down the socket connection.
  Future<void> disconnect();

  /// Joins the appointment room and returns the chronological message history.
  Future<List<ChatMessage>> joinRoom(String appointmentId);

  /// Sends a message and resolves with the server-persisted message.
  Future<ChatMessage> sendMessage({
    required String appointmentId,
    required String body,
  });

  /// Marks the peer's messages as read (all unread when [messageIds] is null).
  Future<void> markRead(String appointmentId, {List<String>? messageIds});

  /// Broadcasts a typing indicator.
  void sendTyping(String appointmentId, {required bool isTyping});
}

/// Raised when a chat operation fails (connection, ack error, or timeout).
class ChatException implements Exception {
  const ChatException(this.message);
  final String message;

  @override
  String toString() => 'ChatException: $message';
}
