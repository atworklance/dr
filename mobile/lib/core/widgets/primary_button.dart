import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The app's hero call-to-action. Renders a gradient pill by default (premium
/// brand look) with an integrated loading state; set [gradient] to false for a
/// flat solid variant. Disabled automatically while [isLoading] or when
/// [onPressed] is null.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.gradient = true,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool gradient;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;

    final Widget child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    if (!gradient) {
      return SizedBox(
        width: expand ? double.infinity : null,
        height: 54,
        child: ElevatedButton(onPressed: enabled ? onPressed : null, child: child),
      );
    }

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          boxShadow: enabled ? AppColors.softShadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            onTap: enabled ? onPressed : null,
            child: Container(
              width: expand ? double.infinity : null,
              height: 54,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
