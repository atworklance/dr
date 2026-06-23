/// Where a consultation takes place. Mirrors the backend `ConsultationMode`
/// enum and is shared by provider profiles, search filters, and bookings.
enum ConsultationMode {
  online,
  clinic;

  /// The wire value sent to / received from the backend.
  String get value => switch (this) {
        ConsultationMode.online => 'online',
        ConsultationMode.clinic => 'clinic',
      };

  /// Parses a backend wire value into a [ConsultationMode].
  static ConsultationMode fromValue(String raw) => switch (raw) {
        'online' => ConsultationMode.online,
        'clinic' => ConsultationMode.clinic,
        _ => throw ArgumentError('Unknown consultation mode: $raw'),
      };
}
