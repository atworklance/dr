import 'package:equatable/equatable.dart';

import 'time_range.dart';

/// A date-specific override of the recurring schedule: either a full day off or
/// a set of custom windows that replace the recurring ones for that date.
class AvailabilityException extends Equatable {
  const AvailabilityException({
    required this.date,
    required this.isFullDayOff,
    this.windows = const [],
    this.reason,
  });

  final DateTime date;
  final bool isFullDayOff;
  final List<TimeRange> windows;
  final String? reason;

  @override
  List<Object?> get props => [date, isFullDayOff, windows, reason];
}
