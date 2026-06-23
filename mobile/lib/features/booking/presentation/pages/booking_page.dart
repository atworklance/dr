import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/entities/consultation_mode.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/booking_request.dart';
import '../../domain/entities/specialist.dart';
import '../../../video/presentation/pages/video_call_page.dart';
import '../bloc/booking/booking_bloc.dart';
import '../widgets/consultation_mode_selector.dart';
import '../widgets/day_selector.dart';
import '../widgets/time_slot_grid.dart';

/// Live booking pipeline: pick mode → day → slot, attach notes, confirm (create
/// the appointment), then capture payment (escrow) and confirm. Provides its own
/// [BookingBloc] from the DI container.
class BookingPage extends StatelessWidget {
  const BookingPage({required this.specialist, super.key});

  final Specialist specialist;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingBloc>(
      create: (_) => sl<BookingBloc>(),
      child: _BookingView(specialist: specialist),
    );
  }
}

class _BookingView extends StatefulWidget {
  const _BookingView({required this.specialist});

  final Specialist specialist;

  @override
  State<_BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<_BookingView> {
  final _notesController = TextEditingController();

  late ConsultationMode _mode;
  late DateTime _day;
  DateTime? _slot;

  Specialist get _specialist => widget.specialist;

  @override
  void initState() {
    super.initState();
    _mode = _specialist.consultationModes.isNotEmpty
        ? _specialist.consultationModes.first
        : ConsultationMode.online;
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _fee => _mode == ConsultationMode.online
      ? _specialist.pricing.onlineFee
      : _specialist.pricing.clinicFee;

  List<DateTime> get _slots {
    final duration = _specialist.pricing.sessionDurationMinutes;
    final dayStart = DateTime(_day.year, _day.month, _day.day, 8);
    final dayEnd = DateTime(_day.year, _day.month, _day.day, 18);
    final slots = <DateTime>[];
    var cursor = dayStart;
    while (!cursor.add(Duration(minutes: duration)).isAfter(dayEnd)) {
      slots.add(cursor);
      cursor = cursor.add(Duration(minutes: duration));
    }
    return slots;
  }

  void _confirmBooking() {
    final slot = _slot;
    if (slot == null) {
      AppSnackBar.showError(context, 'Select a time slot to continue.');
      return;
    }
    final duration = _specialist.pricing.sessionDurationMinutes;
    final notes = _notesController.text.trim();
    context.read<BookingBloc>().add(
          BookingSlotSubmitted(
            BookingRequest(
              providerId: _specialist.id,
              mode: _mode,
              start: slot,
              end: slot.add(Duration(minutes: duration)),
              notes: notes.isEmpty ? null : notes,
            ),
          ),
        );
  }

  void _pay(Appointment appointment) {
    // In production this reference comes from the payment gateway SDK; here we
    // forward a deterministic client reference the backend capture accepts.
    final reference = 'pm_${DateTime.now().millisecondsSinceEpoch}';
    context.read<BookingBloc>().add(
          BookingPaymentSubmitted(
            appointmentId: appointment.id,
            paymentReference: reference,
          ),
        );
  }

  void _showConfirmation(Appointment appointment) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ConfirmationDialog(
        appointment: appointment,
        specialistName: _specialist.displayName,
        onDone: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop();
        },
        onStartVideo: appointment.mode == ConsultationMode.online
            ? () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => VideoCallPage(
                      appointmentId: appointment.id,
                      specialistName: _specialist.displayName,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book ${_specialist.displayName}')),
      body: BlocConsumer<BookingBloc, BookingState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == BookingStatus.failure && state.failure != null) {
            AppSnackBar.showError(context, state.failure!.message);
          } else if (state.status == BookingStatus.paid &&
              state.appointment != null) {
            _showConfirmation(state.appointment!);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _SummaryHeader(specialist: _specialist, mode: _mode),
                    const SizedBox(height: AppSpacing.xl),
                    if (_specialist.consultationModes.length > 1) ...[
                      const _SectionTitle('Consultation type'),
                      ConsultationModeSelector(
                        available: _specialist.consultationModes,
                        selected: _mode,
                        onlineFee: _specialist.pricing.onlineFee,
                        clinicFee: _specialist.pricing.clinicFee,
                        currency: _specialist.pricing.currency,
                        onChanged: (mode) => setState(() => _mode = mode),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    const _SectionTitle('Select a date'),
                    DaySelector(
                      selected: _day,
                      onSelected: (day) => setState(() {
                        _day = day;
                        _slot = null;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionTitle('Available times · ${Formatters.fullDate(_day)}'),
                    TimeSlotGrid(
                      slots: _slots,
                      selected: _slot,
                      onSelected: (slot) => setState(() => _slot = slot),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _SectionTitle('Notes for the specialist (optional)'),
                    AppTextField(
                      label: '',
                      controller: _notesController,
                      hint: 'Briefly describe your symptoms or reason for visit…',
                      maxLines: 4,
                      minLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: const [
                        Icon(Icons.lock_outline_rounded,
                            size: 14, color: AppColors.textTertiary),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Notes are encrypted and shared only with your specialist.',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _BottomBar(
                state: state,
                fee: _fee,
                currency: _specialist.pricing.currency,
                slot: _slot,
                durationMinutes: _specialist.pricing.sessionDurationMinutes,
                onConfirm: _confirmBooking,
                onPay: () => _pay(state.appointment!),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.specialist, required this.mode});

  final Specialist specialist;
  final ConsultationMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded, color: Colors.white, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  specialist.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.durationLabel(specialist.pricing.sessionDurationMinutes)} session',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.state,
    required this.fee,
    required this.currency,
    required this.slot,
    required this.durationMinutes,
    required this.onConfirm,
    required this.onPay,
  });

  final BookingState state;
  final int fee;
  final String currency;
  final DateTime? slot;
  final int durationMinutes;
  final VoidCallback onConfirm;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final bool awaitingPayment =
        state.awaitingPayment || state.status == BookingStatus.paying;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppColors.softShadow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    awaitingPayment ? 'Total due' : 'Session fee',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.money(fee, currency),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (slot != null)
                Flexible(
                  child: Text(
                    '${Formatters.fullDate(slot!)}\n${Formatters.time(slot!)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (awaitingPayment)
            PrimaryButton(
              label: 'Pay ${Formatters.money(fee, currency)}',
              icon: Icons.lock_rounded,
              isLoading: state.status == BookingStatus.paying,
              onPressed: onPay,
            )
          else
            PrimaryButton(
              label: 'Confirm booking',
              icon: Icons.check_rounded,
              isLoading: state.status == BookingStatus.creating,
              onPressed: slot == null ? null : onConfirm,
            ),
        ],
      ),
    );
  }
}

class _ConfirmationDialog extends StatelessWidget {
  const _ConfirmationDialog({
    required this.appointment,
    required this.specialistName,
    required this.onDone,
    this.onStartVideo,
  });

  final Appointment appointment;
  final String specialistName;
  final VoidCallback onDone;
  final VoidCallback? onStartVideo;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Booking confirmed',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your ${Formatters.durationLabel(appointment.durationMinutes)} '
              'session with $specialistName is reserved for '
              '${Formatters.fullDate(appointment.start)} at '
              '${Formatters.time(appointment.start)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      appointment.mode == ConsultationMode.online
                          ? 'A secure video room is ready in your appointment.'
                          : 'Clinic visit — details are in your appointment.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (onStartVideo != null) ...[
              PrimaryButton(
                label: 'Start video consultation',
                icon: Icons.videocam_rounded,
                onPressed: onStartVideo,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: onDone, child: const Text('Later')),
            ] else
              PrimaryButton(label: 'Done', onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
