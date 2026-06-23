import '../../../../core/entities/paged_result.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/appointment.dart';
import '../entities/booking_request.dart';
import '../entities/search_filter.dart';
import '../entities/specialist.dart';

/// Domain contract for the specialist search & live booking system.
abstract interface class BookingRepository {
  /// Paginated specialist directory search.
  ResultFuture<PagedResult<Specialist>> searchSpecialists(SearchFilter filter);

  /// Full profile for a single specialist.
  ResultFuture<Specialist> getSpecialistById(String id);

  /// Books a slot; the backend enforces availability and prevents double-booking.
  ResultFuture<Appointment> bookAppointment(BookingRequest request);

  /// Captures payment for a pending appointment, moving funds into escrow.
  ResultFuture<Appointment> payForAppointment({
    required String appointmentId,
    required String paymentReference,
  });
}
