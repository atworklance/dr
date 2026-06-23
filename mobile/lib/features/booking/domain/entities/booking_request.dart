import 'package:equatable/equatable.dart';

import '../../../../core/entities/consultation_mode.dart';

/// A request to book a specific time slot with a specialist. Maps to the backend
/// `POST /appointments` body. The slot window is validated server-side against
/// the provider's availability matrix, and the unique-index guarantees no
/// double-booking.
class BookingRequest extends Equatable {
  const BookingRequest({
    required this.providerId,
    required this.mode,
    required this.start,
    required this.end,
    this.notes,
  });

  final String providerId;
  final ConsultationMode mode;
  final DateTime start;
  final DateTime end;

  /// Optional client notes; encrypted at rest by the backend.
  final String? notes;

  Duration get duration => end.difference(start);

  @override
  List<Object?> get props => [providerId, mode, start, end, notes];
}
