import 'chat_connection_status.dart';
import 'chat_message.dart';

/// Domain-level events emitted by the realtime chat transport. The presentation
/// layer pattern-matches over this sealed hierarchy exhaustively.
sealed class ChatRealtimeEvent {
  const ChatRealtimeEvent();
}

/// A message was received (from either participant; the sender's own messages
/// are echoed back so multiple devices stay in sync).
class IncomingMessageEvent extends ChatRealtimeEvent {
  const IncomingMessageEvent(this.message);
  final ChatMessage message;
}

/// The peer marked one or more of the current user's messages as read.
class ReadReceiptEvent extends ChatRealtimeEvent {
  const ReadReceiptEvent({required this.by, required this.messageIds});
  final String by;
  final List<String> messageIds;
}

/// The peer started or stopped typing.
class TypingEvent extends ChatRealtimeEvent {
  const TypingEvent({required this.userId, required this.isTyping});
  final String userId;
  final bool isTyping;
}

/// The peer came online or went offline in this conversation.
class PresenceEvent extends ChatRealtimeEvent {
  const PresenceEvent({required this.userId, required this.online});
  final String userId;
  final bool online;
}

/// The socket connection state changed.
class ConnectionStateEvent extends ChatRealtimeEvent {
  const ConnectionStateEvent(this.status);
  final ChatConnectionStatus status;
}

/// The server reported a non-fatal chat error.
class ChatErrorEvent extends ChatRealtimeEvent {
  const ChatErrorEvent(this.message);
  final String message;
}
