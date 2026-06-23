import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/availability_window.dart';
import '../repositories/availability_repository.dart';

/// Persists the recurring weekly schedule.
class UpdateWeeklyAvailability
    extends UseCase<List<AvailabilityWindow>, List<AvailabilityWindow>> {
  UpdateWeeklyAvailability(this._repository);

  final AvailabilityRepository _repository;

  @override
  ResultFuture<List<AvailabilityWindow>> call(List<AvailabilityWindow> params) =>
      _repository.updateWeekly(params);
}
