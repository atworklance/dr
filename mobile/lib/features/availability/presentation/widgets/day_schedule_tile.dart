import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/availability_window.dart';
import '../../domain/entities/time_range.dart';

/// A single weekday row in the weekly schedule editor: its working windows
/// (each with breaks) plus an "add hours" action.
class DayScheduleTile extends StatelessWidget {
  const DayScheduleTile({
    required this.dayLabel,
    required this.windows,
    required this.onAddWindow,
    required this.onRemoveWindow,
    required this.onAddBreak,
    required this.onRemoveBreak,
    super.key,
  });

  final String dayLabel;
  final List<AvailabilityWindow> windows;
  final VoidCallback onAddWindow;
  final ValueChanged<AvailabilityWindow> onRemoveWindow;
  final ValueChanged<AvailabilityWindow> onAddBreak;
  final void Function(AvailabilityWindow window, TimeRange range) onRemoveBreak;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dayLabel,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddWindow,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add hours'),
              ),
            ],
          ),
          if (windows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'Unavailable',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
            )
          else
            ...windows.map((window) => _WindowRow(
                  window: window,
                  onRemove: () => onRemoveWindow(window),
                  onAddBreak: () => onAddBreak(window),
                  onRemoveBreak: (range) => onRemoveBreak(window, range),
                )),
        ],
      ),
    );
  }
}

class _WindowRow extends StatelessWidget {
  const _WindowRow({
    required this.window,
    required this.onRemove,
    required this.onAddBreak,
    required this.onRemoveBreak,
  });

  final AvailabilityWindow window;
  final VoidCallback onRemove;
  final VoidCallback onAddBreak;
  final ValueChanged<TimeRange> onRemoveBreak;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${window.startTime} – ${window.endTime}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 20, color: AppColors.danger),
                onPressed: onRemove,
              ),
            ],
          ),
          if (window.breaks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final br in window.breaks)
                    Chip(
                      label: Text('Break ${br.startTime}–${br.endTime}'),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      visualDensity: VisualDensity.compact,
                      onDeleted: () => onRemoveBreak(br),
                      deleteIconColor: AppColors.textTertiary,
                    ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddBreak,
              icon: const Icon(Icons.free_breakfast_outlined, size: 16),
              label: const Text('Add break'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
