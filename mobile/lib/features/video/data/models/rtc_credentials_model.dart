import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/rtc_credentials.dart';

/// Data-layer representation of [RtcCredentials], parsing the backend video
/// token payload (`expiresAt` arrives as Unix epoch seconds).
class RtcCredentialsModel extends RtcCredentials {
  const RtcCredentialsModel({
    required super.appId,
    required super.channel,
    required super.account,
    required super.token,
    required super.expiresAt,
  });

  factory RtcCredentialsModel.fromJson(DataMap json) {
    final expiresRaw = json['expiresAt'];
    final expiresSeconds = expiresRaw is num
        ? expiresRaw.toInt()
        : int.tryParse('$expiresRaw') ?? 0;

    return RtcCredentialsModel(
      appId: json['appId'] as String,
      channel: json['channel'] as String,
      account: json['account'].toString(),
      token: json['token'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresSeconds * 1000),
    );
  }
}
