import '../../../../core/utils/typedefs.dart';
import '../entities/rtc_credentials.dart';

/// Domain contract for the live video session: token issuance and session
/// state transitions on the backend.
abstract interface class VideoRepository {
  /// Fetches a fresh Agora RTC token for the appointment's channel.
  ResultFuture<RtcCredentials> getToken(String appointmentId);

  /// Notifies the backend that the participant has joined the live session.
  ResultVoid startSession(String appointmentId);

  /// Notifies the backend that the live session has ended.
  ResultVoid endSession(String appointmentId);
}
