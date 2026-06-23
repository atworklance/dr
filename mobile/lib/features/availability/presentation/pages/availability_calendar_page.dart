import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/availability_exception.dart';
import '../../domain/entities/time_range.dart';
import '../cubit/availability_cubit.dart';
import '../widgets/add_exception_sheet.dart';
import '../widgets/day_schedule_tile.dart';
import '../widgets/schedule_time_picker.dart';

/// Weekday order (Monday-first) with backend weekday indices (0 = Sunday).
const List<({int index, String label})> _weekOrder = [
  (index: 1, label: 'Monday'),
  (index: 2, label: 'Tuesday'),
  (index: 3, label: 'Wednesday'),
  (index: 4, label: 'Thursday'),
  (index: 5, label: 'Friday'),
  (index: 6, label: 'Saturday'),
  (index: 0, label: 'Sunday'),
];

/// Provider availability editor: Holiday Mode, recurring weekly windows with
/// breaks, and date exceptions. Self-provides its [AvailabilityCubit].
class AvailabilityCalendarPage extends StatelessWidget {
  const AvailabilityCalendarPage({super.key, this.appBarActions});

  final List<Widget>? appBarActions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AvailabilityCubit>(
      create: (_) => sl<AvailabilityCubit>()..load(),
      child: _AvailabilityView(appBarActions: appBarActions),
    );
  }
}

class _AvailabilityView extends StatelessWidget {
  const _AvailabilityView({this.appBarActions});

  final List<Widget>? appBarActions;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AvailabilityCubit, AvailabilityState>(
      listenWhen: (p, c) => p.errorMessage != c.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppSnackBar.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Availability'), actions: appBarActions),
          body: _buildBody(context, state),
          bottomNavigationBar: state.isDirty ? _SaveBar(state: state) : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AvailabilityState state) {
    if (state.status == AvailabilityStatus.loading ||
        state.status == AvailabilityStatus.initial) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (!state.isReady) {
      return _ErrorRetry(
        message: state.errorMessage ?? 'Could not load availability.',
        onRetry: () => context.read<AvailabilityCubit>().load(),
      );
    }

    final cubit = context.read<AvailabilityCubit>();
    final availability = state.availability!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _HolidayCard(
          enabled: availability.holidayMode,
          busy: state.isMutating,
          onChanged: cubit.setHolidayMode,
        ),
        const SizedBox(height: AppSpacing.md),
        _InfoRow(
          icon: Icons.how_to_reg_rounded,
          label: 'Accepting new clients',
          value: availability.isAcceptingNewClients ? 'Yes' : 'No',
        ),
        _InfoRow(
          icon: Icons.timelapse_rounded,
          label: 'Booking lead time',
          value: Formatters.durationLabel(availability.bookingLeadTimeMinutes),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionHeader('Weekly schedule'),
        for (final day in _weekOrder)
          DayScheduleTile(
            dayLabel: day.label,
            windows: state.draftForDay(day.index),
            onAddWindow: () async {
              final range = await pickTimeRange(context);
              if (range != null) cubit.addWindow(day.index, range);
            },
            onRemoveWindow: cubit.removeWindow,
            onAddBreak: (window) async {
              final range = await pickTimeRange(
                context,
                confine: TimeRange(
                  startTime: window.startTime,
                  endTime: window.endTime,
                ),
              );
              if (range != null) cubit.addBreak(window, range);
            },
            onRemoveBreak: cubit.removeBreak,
          ),
        const SizedBox(height: AppSpacing.lg),
        const _SectionHeader('Date exceptions'),
        _ExceptionsSection(
          exceptions: availability.exceptions,
          onAdd: () async {
            final exception = await showAddExceptionSheet(context);
            if (exception != null) cubit.addException(exception);
          },
        ),
      ],
    );
  }
}

class _HolidayCard extends StatelessWidget {
  const _HolidayCard({
    required this.enabled,
    required this.busy,
    required this.onChanged,
  });

  final bool enabled;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.brandGradient : null,
        color: enabled ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Icon(
            Icons.beach_access_rounded,
            color: enabled ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Holiday Mode',
                  style: TextStyle(
                    color: enabled ? Colors.white : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  enabled ? 'You are unbookable' : 'Pause all new bookings',
                  style: TextStyle(
                    color: enabled ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (busy)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
            )
          else
            Switch.adaptive(
              value: enabled,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: Colors.white38,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExceptionsSection extends StatelessWidget {
  const _ExceptionsSection({required this.exceptions, required this.onAdd});

  final List<AvailabilityException> exceptions;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (exceptions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No exceptions set.',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
          )
        else
          ...exceptions.map((e) => _ExceptionRow(exception: e)),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.event_busy_rounded, size: 18),
          label: const Text('Add date exception'),
        ),
      ],
    );
  }
}

class _ExceptionRow extends StatelessWidget {
  const _ExceptionRow({required this.exception});

  final AvailabilityException exception;

  @override
  Widget build(BuildContext context) {
    final subtitle = exception.isFullDayOff
        ? 'Full day off'
        : exception.windows.map((w) => '${w.startTime}–${w.endTime}').join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.event_busy_rounded, size: 20, color: AppColors.danger),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.fullDate(exception.date),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.state});

  final AvailabilityState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AvailabilityCubit>();
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: state.isSaving ? null : cubit.discardChanges,
            child: const Text('Discard'),
          ),
          const Spacer(),
          SizedBox(
            width: 160,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: state.isSaving ? null : cubit.saveWeekly,
              icon: state.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save schedule'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
