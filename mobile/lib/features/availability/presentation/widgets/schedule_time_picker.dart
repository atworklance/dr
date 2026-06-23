import 'package:flutter/material.dart';

import '../../domain/entities/time_range.dart';

/// `TimeOfDay` -> `HH:mm` wire string.
String formatTimeOfDay(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

TimeOfDay _parse(String value, {required TimeOfDay fallback}) {
  final parts = value.split(':');
  if (parts.length != 2) return fallback;
  final h = int.tryParse(parts.first);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return fallback;
  return TimeOfDay(hour: h, minute: m);
}

/// Prompts for a start and end time and returns a valid [TimeRange] (end after
/// start), or null if cancelled / invalid. Optional [confine] bounds the range
/// inside a parent window (used for breaks).
Future<TimeRange?> pickTimeRange(
  BuildContext context, {
  TimeRange? initial,
  TimeRange? confine,
}) async {
  final startSeed = initial != null
      ? _parse(initial.startTime, fallback: const TimeOfDay(hour: 9, minute: 0))
      : const TimeOfDay(hour: 9, minute: 0);

  final start = await showTimePicker(
    context: context,
    initialTime: startSeed,
    helpText: 'Select start time',
  );
  if (start == null || !context.mounted) return null;

  final end = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute),
    helpText: 'Select end time',
  );
  if (end == null) return null;

  final range = TimeRange(
    startTime: formatTimeOfDay(start),
    endTime: formatTimeOfDay(end),
  );
  if (!range.isValid) return null;

  if (confine != null &&
      (range.startMinutes < confine.startMinutes ||
          range.endMinutes > confine.endMinutes)) {
    return null;
  }
  return range;
}
