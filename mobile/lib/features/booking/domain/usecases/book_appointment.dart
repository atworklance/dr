import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/appointment.dart';
import '../entities/booking_request.dart';
import '../repositories/booking_repository.dart';

/// Books an appointment slot with a specialist.
class BookAppointment extends UseCase<Appointment, BookingRequest> {
  BookAppointment(this._repository);

  final BookingRepository _repository;

  @override
  ResultFuture<Appointment> call(BookingRequest params) =>
      _repository.bookAppointment(params);
}
