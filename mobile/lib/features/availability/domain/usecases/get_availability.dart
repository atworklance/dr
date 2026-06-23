import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/provider_availability.dart';
import '../repositories/availability_repository.dart';

/// Loads the provider's availability matrix.
class GetAvailability extends UseCaseWithoutParams<ProviderAvailability> {
  GetAvailability(this._repository);

  final AvailabilityRepository _repository;

  @override
  ResultFuture<ProviderAvailability> call() => _repository.getAvailability();
}
