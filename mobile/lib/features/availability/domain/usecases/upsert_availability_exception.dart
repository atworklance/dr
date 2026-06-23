import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/availability_exception.dart';
import '../repositories/availability_repository.dart';

/// Adds or replaces a date-specific availability exception.
class UpsertAvailabilityException
    extends UseCase<List<AvailabilityException>, AvailabilityException> {
  UpsertAvailabilityException(this._repository);

  final AvailabilityRepository _repository;

  @override
  ResultFuture<List<AvailabilityException>> call(AvailabilityException params) =>
      _repository.upsertException(params);
}
