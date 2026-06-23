import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/availability_repository.dart';

/// Toggles the provider's Holiday Mode.
class SetHolidayMode extends UseCase<bool, bool> {
  SetHolidayMode(this._repository);

  final AvailabilityRepository _repository;

  @override
  ResultFuture<bool> call(bool params) => _repository.setHolidayMode(params);
}
