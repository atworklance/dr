import 'package:equatable/equatable.dart';

/// A live incoming consultation call signalled to the provider.
class IncomingCall extends Equatable {
  const IncomingCall({
    required this.appointmentId,
    required this.channelName,
    required this.callerId,
    required this.receivedAt,
    this.startsAt,
  });

  final String appointmentId;
  final String channelName;

  /// The user id of the participant who started the call.
  final String callerId;
  final DateTime receivedAt;

  /// The scheduled start of the appointment, when known.
  final DateTime? startsAt;

  @override
  List<Object?> get props =>
      [appointmentId, channelName, callerId, receivedAt, startsAt];
}
