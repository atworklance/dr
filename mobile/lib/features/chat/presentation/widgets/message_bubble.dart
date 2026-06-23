import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/chat_message.dart';
import 'message_receipt.dart';

/// A single chat bubble. Own messages align right with a brand gradient and
/// receipt ticks; peer messages align left on a muted surface. Failed sends
/// expose a tap-to-retry affordance.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    this.onRetry,
    super.key,
  });

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final bool mine = message.isMine;
    final bool failed = message.status == MessageDeliveryStatus.failed;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: mine ? AppColors.brandGradient : null,
        color: mine ? null : AppColors.surfaceMuted,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppSpacing.radius),
          topRight: const Radius.circular(AppSpacing.radius),
          bottomLeft: Radius.circular(mine ? AppSpacing.radius : 4),
          bottomRight: Radius.circular(mine ? 4 : AppSpacing.radius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.body,
            style: TextStyle(
              color: mine ? Colors.white : AppColors.textPrimary,
              fontSize: 15,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Formatters.time(message.createdAt),
                style: TextStyle(
                  color: mine ? Colors.white70 : AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
              if (mine) ...[
                const SizedBox(width: 4),
                MessageReceipt(status: message.status),
              ],
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          bubble,
          if (failed && mine)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 2),
              child: GestureDetector(
                onTap: onRetry,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.refresh_rounded, size: 13, color: AppColors.danger),
                    SizedBox(width: 2),
                    Text(
                      'Tap to retry',
                      style: TextStyle(color: AppColors.danger, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
