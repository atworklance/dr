import 'package:equatable/equatable.dart';

/// A start–end time range expressed as `HH:mm` 24-hour strings, matching the
/// backend availability schema. Used for working windows and session breaks.
class TimeRange extends Equatable {
  const TimeRange({required this.startTime, required this.endTime});

  final String startTime;
  final String endTime;

  int get startMinutes => _toMinutes(startTime);
  int get endMinutes => _toMinutes(endTime);

  /// True when [endTime] is strictly after [startTime].
  bool get isValid => endMinutes > startMinutes;

  static int _toMinutes(String value) {
    final parts = value.split(':');
    return (int.tryParse(parts.first) ?? 0) * 60 +
        (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }

  @override
  List<Object?> get props => [startTime, endTime];
}
