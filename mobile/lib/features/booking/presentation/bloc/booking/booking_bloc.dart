import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/appointment.dart';
import '../../../domain/entities/booking_request.dart';
import '../../../domain/usecases/book_appointment.dart';
import '../../../domain/usecases/pay_for_appointment.dart';

part 'booking_event.dart';
part 'booking_state.dart';

/// Drives the live booking pipeline: create the appointment, then capture
/// payment (which the backend places into escrow). Each step folds its
/// `Either` result into a discrete [BookingStatus].
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc({
    required BookAppointment bookAppointment,
    required PayForAppointment payForAppointment,
  })  : _bookAppointment = bookAppointment,
        _payForAppointment = payForAppointment,
        super(const BookingState()) {
    on<BookingSlotSubmitted>(_onSlotSubmitted);
    on<BookingPaymentSubmitted>(_onPaymentSubmitted);
    on<BookingReset>(_onReset);
  }

  final BookAppointment _bookAppointment;
  final PayForAppointment _payForAppointment;

  Future<void> _onSlotSubmitted(
    BookingSlotSubmitted event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.creating, clearFailure: true));
    final result = await _bookAppointment(event.request);
    result.fold(
      (failure) => emit(state.copyWith(status: BookingStatus.failure, failure: failure)),
      (appointment) => emit(state.copyWith(
        status: BookingStatus.created,
        appointment: appointment,
        clearFailure: true,
      )),
    );
  }

  Future<void> _onPaymentSubmitted(
    BookingPaymentSubmitted event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.paying, clearFailure: true));
    final result = await _payForAppointment(
      PayForAppointmentParams(
        appointmentId: event.appointmentId,
        paymentReference: event.paymentReference,
      ),
    );
    result.fold(
      (failure) => emit(state.copyWith(status: BookingStatus.failure, failure: failure)),
      (appointment) => emit(state.copyWith(
        status: BookingStatus.paid,
        appointment: appointment,
        clearFailure: true,
      )),
    );
  }

  void _onReset(BookingReset event, Emitter<BookingState> emit) {
    emit(const BookingState());
  }
}
