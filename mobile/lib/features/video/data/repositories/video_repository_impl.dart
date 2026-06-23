import '../../../../core/network/network_info.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/rtc_credentials.dart';
import '../../domain/repositories/video_repository.dart';
import '../datasources/video_remote_data_source.dart';

/// Implements [VideoRepository] over the remote data source, translating
/// data-layer exceptions into domain [Failure]s and short-circuiting offline.
class VideoRepositoryImpl implements VideoRepository {
  VideoRepositoryImpl({
    required VideoRemoteDataSource remote,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _networkInfo = networkInfo;

  final VideoRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<RtcCredentials> getToken(String appointmentId) {
    return guardRemote(_networkInfo, () => _remote.getToken(appointmentId));
  }

  @override
  ResultVoid startSession(String appointmentId) {
    return guardRemoteVoid(_networkInfo, () => _remote.startSession(appointmentId));
  }

  @override
  ResultVoid endSession(String appointmentId) {
    return guardRemoteVoid(_networkInfo, () => _remote.endSession(appointmentId));
  }
}
