import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/specialist.dart';
import '../repositories/booking_repository.dart';

/// Loads a single specialist's full profile by id.
class GetSpecialistDetails extends UseCase<Specialist, String> {
  GetSpecialistDetails(this._repository);

  final BookingRepository _repository;

  @override
  ResultFuture<Specialist> call(String params) =>
      _repository.getSpecialistById(params);
}
