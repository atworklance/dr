import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/appointment.dart';
import '../repositories/booking_repository.dart';

/// Captures payment for a pending appointment, moving the provider's net share
/// into escrow on the backend.
class PayForAppointment extends UseCase<Appointment, PayForAppointmentParams> {
  PayForAppointment(this._repository);

  final BookingRepository _repository;

  @override
  ResultFuture<Appointment> call(PayForAppointmentParams params) =>
      _repository.payForAppointment(
        appointmentId: params.appointmentId,
        paymentReference: params.paymentReference,
      );
}

class PayForAppointmentParams extends Equatable {
  const PayForAppointmentParams({
    required this.appointmentId,
    required this.paymentReference,
  });

  final String appointmentId;
  final String paymentReference;

  @override
  List<Object?> get props => [appointmentId, paymentReference];
}
