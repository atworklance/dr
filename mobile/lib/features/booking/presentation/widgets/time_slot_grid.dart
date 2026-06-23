import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';

/// A wrap-grid of selectable time slots for the chosen day. Slots already in
/// the past are disabled. Final availability is validated server-side on submit.
class TimeSlotGrid extends StatelessWidget {
  const TimeSlotGrid({
    required this.slots,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<DateTime> slots;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: const Text(
          'No slots remaining for this day. Try another date.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final now = DateTime.now();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final slot in slots)
          _SlotChip(
            time: Formatters.time(slot),
            selected: selected != null && selected!.isAtSameMomentAs(slot),
            disabled: slot.isBefore(now),
            onTap: () => onSelected(slot),
          ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.time,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String time;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = disabled
        ? AppColors.textTertiary
        : (selected ? Colors.white : AppColors.textPrimary);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: selected && !disabled ? AppColors.brandGradient : null,
          color: selected && !disabled ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w600,
            decoration: disabled ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
