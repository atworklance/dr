import 'package:equatable/equatable.dart';

import 'availability_exception.dart';
import 'availability_window.dart';

/// The complete availability matrix for a provider: recurring weekly windows,
/// date-specific exceptions, the Holiday Mode switch, the booking lead time, and
/// whether the provider is accepting new clients.
class ProviderAvailability extends Equatable {
  const ProviderAvailability({
    required this.weeklyAvailability,
    required this.exceptions,
    required this.holidayMode,
    required this.bookingLeadTimeMinutes,
    required this.isAcceptingNewClients,
  });

  final List<AvailabilityWindow> weeklyAvailability;
  final List<AvailabilityException> exceptions;
  final bool holidayMode;
  final int bookingLeadTimeMinutes;
  final bool isAcceptingNewClients;

  /// Recurring windows for a weekday (0 = Sunday … 6 = Saturday), time-sorted.
  List<AvailabilityWindow> windowsForDay(int weekday) {
    final windows =
        weeklyAvailability.where((w) => w.weekday == weekday).toList();
    windows.sort((a, b) => a.startTime.compareTo(b.startTime));
    return windows;
  }

  ProviderAvailability copyWith({
    List<AvailabilityWindow>? weeklyAvailability,
    List<AvailabilityException>? exceptions,
    bool? holidayMode,
    int? bookingLeadTimeMinutes,
    bool? isAcceptingNewClients,
  }) {
    return ProviderAvailability(
      weeklyAvailability: weeklyAvailability ?? this.weeklyAvailability,
      exceptions: exceptions ?? this.exceptions,
      holidayMode: holidayMode ?? this.holidayMode,
      bookingLeadTimeMinutes:
          bookingLeadTimeMinutes ?? this.bookingLeadTimeMinutes,
      isAcceptingNewClients:
          isAcceptingNewClients ?? this.isAcceptingNewClients,
    );
  }

  @override
  List<Object?> get props => [
        weeklyAvailability,
        exceptions,
        holidayMode,
        bookingLeadTimeMinutes,
        isAcceptingNewClients,
      ];
}
