import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/chat_message.dart';

/// Maps the backend chat message DTO into a domain [ChatMessage], resolving
/// ownership and receipt-derived delivery status against [currentUserId].
abstract final class ChatMessageModel {
  static ChatMessage fromDto(DataMap dto, String currentUserId) {
    final senderId = (dto['sender'] ?? '').toString();
    final deliveredAt = _date(dto['deliveredAt']);
    final readAt = _date(dto['readAt']);
    final isMine = senderId == currentUserId;

    final MessageDeliveryStatus status;
    if (!isMine) {
      status = MessageDeliveryStatus.delivered;
    } else if (readAt != null) {
      status = MessageDeliveryStatus.read;
    } else if (deliveredAt != null) {
      status = MessageDeliveryStatus.delivered;
    } else {
      status = MessageDeliveryStatus.sent;
    }

    return ChatMessage(
      id: (dto['id'] ?? dto['_id'] ?? '').toString(),
      appointmentId: (dto['appointment'] ?? '').toString(),
      senderId: senderId,
      body: dto['body'] as String? ?? '',
      isMine: isMine,
      status: status,
      createdAt: _date(dto['createdAt']) ?? DateTime.now(),
      deliveredAt: deliveredAt,
      readAt: readAt,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
