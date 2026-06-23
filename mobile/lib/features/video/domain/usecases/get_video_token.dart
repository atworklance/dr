import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/rtc_credentials.dart';
import '../repositories/video_repository.dart';

/// Issues Agora RTC credentials for an appointment's video channel.
class GetVideoToken extends UseCase<RtcCredentials, String> {
  GetVideoToken(this._repository);

  final VideoRepository _repository;

  @override
  ResultFuture<RtcCredentials> call(String params) =>
      _repository.getToken(params);
}
