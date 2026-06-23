import 'package:flutter/material.dart';

import '../../../../core/entities/consultation_mode.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';

/// Segmented selector for the consultation mode on the booking screen. Only the
/// modes the specialist actually offers are shown, each with its fee.
class ConsultationModeSelector extends StatelessWidget {
  const ConsultationModeSelector({
    required this.available,
    required this.selected,
    required this.onlineFee,
    required this.clinicFee,
    required this.currency,
    required this.onChanged,
    super.key,
  });

  final List<ConsultationMode> available;
  final ConsultationMode selected;
  final int onlineFee;
  final int clinicFee;
  final String currency;
  final ValueChanged<ConsultationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final mode in available) ...[
          Expanded(
            child: _ModeTile(
              mode: mode,
              selected: selected == mode,
              fee: mode == ConsultationMode.online ? onlineFee : clinicFee,
              currency: currency,
              onTap: () => onChanged(mode),
            ),
          ),
          if (mode != available.last) const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.selected,
    required this.fee,
    required this.currency,
    required this.onTap,
  });

  final ConsultationMode mode;
  final bool selected;
  final int fee;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool online = mode == ConsultationMode.online;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              online ? Icons.videocam_rounded : Icons.local_hospital_rounded,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              online ? 'Online visit' : 'Clinic visit',
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              Formatters.money(fee, currency),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
