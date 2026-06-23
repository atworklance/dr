import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/availability_exception.dart';
import '../../domain/entities/time_range.dart';
import 'schedule_time_picker.dart';

/// Bottom-sheet form to create a date-specific availability exception
/// (full day off, or custom windows). Resolves with the exception, or null.
Future<AvailabilityException?> showAddExceptionSheet(BuildContext context) {
  return showModalBottomSheet<AvailabilityException>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: const _AddExceptionSheet(),
    ),
  );
}

class _AddExceptionSheet extends StatefulWidget {
  const _AddExceptionSheet();

  @override
  State<_AddExceptionSheet> createState() => _AddExceptionSheetState();
}

class _AddExceptionSheetState extends State<_AddExceptionSheet> {
  final _reasonController = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _fullDayOff = true;
  final List<TimeRange> _windows = [];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _addWindow() async {
    final range = await pickTimeRange(context);
    if (range != null) setState(() => _windows.add(range));
  }

  void _submit() {
    final exception = AvailabilityException(
      date: _date,
      isFullDayOff: _fullDayOff,
      windows: _fullDayOff ? const [] : List.of(_windows),
      reason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
    );
    Navigator.of(context).pop(exception);
  }

  bool get _canSubmit => _fullDayOff || _windows.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add date exception',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    Formatters.fullDate(_date),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_calendar_outlined,
                      size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _fullDayOff,
            onChanged: (v) => setState(() => _fullDayOff = v),
            activeColor: AppColors.primary,
            title: const Text(
              'Full day off',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Block the entire day',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          if (!_fullDayOff) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final w in _windows)
                  Chip(
                    label: Text('${w.startTime}–${w.endTime}'),
                    onDeleted: () => setState(() => _windows.remove(w)),
                    backgroundColor: AppColors.surfaceMuted,
                    side: BorderSide.none,
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add window'),
                  onPressed: _addWindow,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(hintText: 'Reason (optional)'),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Save exception',
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
