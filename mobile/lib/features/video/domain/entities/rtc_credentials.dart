import 'package:equatable/equatable.dart';

/// Short-lived Agora RTC credentials issued by the backend for an appointment's
/// video channel. The [account] binds the [token] to this user.
class RtcCredentials extends Equatable {
  const RtcCredentials({
    required this.appId,
    required this.channel,
    required this.account,
    required this.token,
    required this.expiresAt,
  });

  final String appId;
  final String channel;
  final String account;
  final String token;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [appId, channel, account, token, expiresAt];
}
