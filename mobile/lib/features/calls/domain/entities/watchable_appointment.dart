import 'package:equatable/equatable.dart';

/// A confirmed appointment whose room the provider joins to receive incoming
/// call signals.
class WatchableAppointment extends Equatable {
  const WatchableAppointment({
    required this.id,
    this.channelName,
    this.startsAt,
  });

  final String id;
  final String? channelName;
  final DateTime? startsAt;

  @override
  List<Object?> get props => [id, channelName, startsAt];
}
