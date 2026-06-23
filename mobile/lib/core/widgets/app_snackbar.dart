import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Consistent, premium snackbars for success and failure feedback.
abstract final class AppSnackBar {
  static void showError(BuildContext context, String message) =>
      _show(context, message, AppColors.danger, Icons.error_outline_rounded);

  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, AppColors.success, Icons.check_circle_outline_rounded);

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          elevation: 6,
          margin: const EdgeInsets.all(AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          content: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
