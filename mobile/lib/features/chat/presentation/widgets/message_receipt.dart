import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';

/// Small status glyph shown on the current user's own message bubbles:
/// clock (sending) → single check (sent) → double check (delivered) →
/// blue double check (read) → error (failed).
class MessageReceipt extends StatelessWidget {
  const MessageReceipt({required this.status, super.key});

  final MessageDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MessageDeliveryStatus.sending =>
        const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
      MessageDeliveryStatus.sent =>
        const Icon(Icons.check_rounded, size: 14, color: Colors.white70),
      MessageDeliveryStatus.delivered =>
        const Icon(Icons.done_all_rounded, size: 14, color: Colors.white70),
      MessageDeliveryStatus.read =>
        const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF8FE1FF)),
      MessageDeliveryStatus.failed =>
        const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFFFD7D7)),
    };
  }
}
