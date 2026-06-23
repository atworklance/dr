import '../../../../core/utils/typedefs.dart';
import '../entities/availability_exception.dart';
import '../entities/availability_window.dart';
import '../entities/provider_availability.dart';

/// Domain contract for managing the authenticated provider's availability.
abstract interface class AvailabilityRepository {
  /// Loads the full availability matrix.
  ResultFuture<ProviderAvailability> getAvailability();

  /// Replaces the recurring weekly windows; returns the persisted windows.
  ResultFuture<List<AvailabilityWindow>> updateWeekly(
    List<AvailabilityWindow> windows,
  );

  /// Upserts a date-specific exception; returns the full exception list.
  ResultFuture<List<AvailabilityException>> upsertException(
    AvailabilityException exception,
  );

  /// Toggles Holiday Mode; returns the new value.
  ResultFuture<bool> setHolidayMode(bool enabled);
}
