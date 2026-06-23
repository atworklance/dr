part of 'booking_bloc.dart';

sealed class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => const [];
}

/// Submits a slot to create a (pending-payment) appointment.
class BookingSlotSubmitted extends BookingEvent {
  const BookingSlotSubmitted(this.request);

  final BookingRequest request;

  @override
  List<Object?> get props => [request];
}

/// Captures payment for the just-created appointment, moving funds into escrow.
class BookingPaymentSubmitted extends BookingEvent {
  const BookingPaymentSubmitted({
    required this.appointmentId,
    required this.paymentReference,
  });

  final String appointmentId;
  final String paymentReference;

  @override
  List<Object?> get props => [appointmentId, paymentReference];
}

/// Resets the flow back to idle (e.g. when leaving the booking screen).
class BookingReset extends BookingEvent {
  const BookingReset();
}
