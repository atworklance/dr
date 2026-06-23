import 'package:equatable/equatable.dart';

import 'time_range.dart';

/// A recurring weekly working window on a given [weekday] (0 = Sunday … 6 =
/// Saturday, matching the backend `Weekday` enum), with optional intra-window
/// session breaks.
class AvailabilityWindow extends Equatable {
  const AvailabilityWindow({
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.breaks = const [],
  });

  final int weekday;
  final String startTime;
  final String endTime;
  final List<TimeRange> breaks;

  AvailabilityWindow copyWith({
    String? startTime,
    String? endTime,
    List<TimeRange>? breaks,
  }) {
    return AvailabilityWindow(
      weekday: weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breaks: breaks ?? this.breaks,
    );
  }

  @override
  List<Object?> get props => [weekday, startTime, endTime, breaks];
}
