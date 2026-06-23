import '../../../../core/network/network_info.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/availability_exception.dart';
import '../../domain/entities/availability_window.dart';
import '../../domain/entities/provider_availability.dart';
import '../../domain/repositories/availability_repository.dart';
import '../datasources/availability_remote_data_source.dart';

class AvailabilityRepositoryImpl implements AvailabilityRepository {
  AvailabilityRepositoryImpl({
    required AvailabilityRemoteDataSource remote,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _networkInfo = networkInfo;

  final AvailabilityRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<ProviderAvailability> getAvailability() {
    return guardRemote(_networkInfo, () => _remote.getAvailability());
  }

  @override
  ResultFuture<List<AvailabilityWindow>> updateWeekly(
    List<AvailabilityWindow> windows,
  ) {
    return guardRemote(_networkInfo, () => _remote.updateWeekly(windows));
  }

  @override
  ResultFuture<List<AvailabilityException>> upsertException(
    AvailabilityException exception,
  ) {
    return guardRemote(_networkInfo, () => _remote.upsertException(exception));
  }

  @override
  ResultFuture<bool> setHolidayMode(bool enabled) {
    return guardRemote(_networkInfo, () => _remote.setHolidayMode(enabled));
  }
}
