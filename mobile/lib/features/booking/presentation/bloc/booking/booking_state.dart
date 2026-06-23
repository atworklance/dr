part of 'booking_bloc.dart';

enum BookingStatus {
  /// No booking in progress.
  idle,

  /// Creating the appointment.
  creating,

  /// Appointment created and awaiting payment.
  created,

  /// Capturing payment.
  paying,

  /// Payment captured; appointment confirmed and in escrow.
  paid,

  /// The last action failed.
  failure,
}

class BookingState extends Equatable {
  const BookingState({
    this.status = BookingStatus.idle,
    this.appointment,
    this.failure,
  });

  final BookingStatus status;
  final Appointment? appointment;
  final Failure? failure;

  bool get isBusy =>
      status == BookingStatus.creating || status == BookingStatus.paying;
  bool get awaitingPayment => status == BookingStatus.created;
  bool get isConfirmed => status == BookingStatus.paid;

  BookingState copyWith({
    BookingStatus? status,
    Appointment? appointment,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return BookingState(
      status: status ?? this.status,
      appointment: appointment ?? this.appointment,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, appointment, failure];
}
