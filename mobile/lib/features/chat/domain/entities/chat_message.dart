import 'package:equatable/equatable.dart';

/// Delivery lifecycle of a message the current user sent. Incoming messages use
/// [delivered]/[read] purely to drive the peer's read state; only the sender's
/// own bubbles surface receipt ticks in the UI.
enum MessageDeliveryStatus { sending, sent, delivered, read, failed }

/// A single chat message within an appointment conversation.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.appointmentId,
    required this.senderId,
    required this.body,
    required this.isMine,
    required this.status,
    required this.createdAt,
    this.deliveredAt,
    this.readAt,
    this.isOptimistic = false,
  });

  final String id;
  final String appointmentId;
  final String senderId;
  final String body;
  final bool isMine;
  final MessageDeliveryStatus status;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  /// True while this is a locally-created bubble awaiting server confirmation.
  final bool isOptimistic;

  ChatMessage copyWith({
    String? id,
    MessageDeliveryStatus? status,
    DateTime? deliveredAt,
    DateTime? readAt,
    bool? isOptimistic,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      appointmentId: appointmentId,
      senderId: senderId,
      body: body,
      isMine: isMine,
      status: status ?? this.status,
      createdAt: createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        senderId,
        body,
        isMine,
        status,
        createdAt,
        deliveredAt,
        readAt,
        isOptimistic,
      ];
}
