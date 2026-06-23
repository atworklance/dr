import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/availability_exception.dart';
import '../../domain/entities/availability_window.dart';
import '../../domain/entities/provider_availability.dart';
import '../../domain/entities/time_range.dart';

/// (De)serialisation for the availability matrix, matching the backend schema.
abstract final class AvailabilityMapper {
  static TimeRange timeRangeFromJson(DataMap json) => TimeRange(
        startTime: json['startTime'] as String? ?? '00:00',
        endTime: json['endTime'] as String? ?? '00:00',
      );

  static DataMap timeRangeToJson(TimeRange range) => <String, dynamic>{
        'startTime': range.startTime,
        'endTime': range.endTime,
      };

  static AvailabilityWindow windowFromJson(DataMap json) => AvailabilityWindow(
        weekday: (json['weekday'] as num?)?.toInt() ?? 0,
        startTime: json['startTime'] as String? ?? '09:00',
        endTime: json['endTime'] as String? ?? '17:00',
        breaks: _list(json['breaks']).map(timeRangeFromJson).toList(),
      );

  static DataMap windowToJson(AvailabilityWindow window) => <String, dynamic>{
        'weekday': window.weekday,
        'startTime': window.startTime,
        'endTime': window.endTime,
        'breaks': window.breaks.map(timeRangeToJson).toList(),
      };

  static AvailabilityException exceptionFromJson(DataMap json) =>
      AvailabilityException(
        date: DateTime.tryParse(json['date'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        isFullDayOff: json['isFullDayOff'] as bool? ?? true,
        windows: _list(json['windows']).map(timeRangeFromJson).toList(),
        reason: json['reason'] as String?,
      );

  static DataMap exceptionToJson(AvailabilityException exception) =>
      <String, dynamic>{
        'date': DateTime.utc(
          exception.date.year,
          exception.date.month,
          exception.date.day,
        ).toIso8601String(),
        'isFullDayOff': exception.isFullDayOff,
        'windows': exception.windows.map(timeRangeToJson).toList(),
        if (exception.reason != null && exception.reason!.isNotEmpty)
          'reason': exception.reason,
      };

  static ProviderAvailability availabilityFromJson(DataMap json) =>
      ProviderAvailability(
        weeklyAvailability:
            _list(json['weeklyAvailability']).map(windowFromJson).toList(),
        exceptions:
            _list(json['availabilityExceptions']).map(exceptionFromJson).toList(),
        holidayMode: json['holidayMode'] as bool? ?? false,
        bookingLeadTimeMinutes:
            (json['bookingLeadTimeMinutes'] as num?)?.toInt() ?? 60,
        isAcceptingNewClients: json['isAcceptingNewClients'] as bool? ?? true,
      );

  static List<DataMap> _list(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    return const [];
  }
}
