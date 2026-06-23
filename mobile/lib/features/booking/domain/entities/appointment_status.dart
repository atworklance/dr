/// Lifecycle state of an appointment. Mirrors the backend `AppointmentStatus`.
enum AppointmentStatus {
  pendingPayment,
  confirmed,
  inProgress,
  completed,
  cancelledByClient,
  cancelledByProvider,
  noShow,
  expired;

  String get value => switch (this) {
        AppointmentStatus.pendingPayment => 'pending_payment',
        AppointmentStatus.confirmed => 'confirmed',
        AppointmentStatus.inProgress => 'in_progress',
        AppointmentStatus.completed => 'completed',
        AppointmentStatus.cancelledByClient => 'cancelled_by_client',
        AppointmentStatus.cancelledByProvider => 'cancelled_by_provider',
        AppointmentStatus.noShow => 'no_show',
        AppointmentStatus.expired => 'expired',
      };

  static AppointmentStatus fromValue(String raw) => switch (raw) {
        'pending_payment' => AppointmentStatus.pendingPayment,
        'confirmed' => AppointmentStatus.confirmed,
        'in_progress' => AppointmentStatus.inProgress,
        'completed' => AppointmentStatus.completed,
        'cancelled_by_client' => AppointmentStatus.cancelledByClient,
        'cancelled_by_provider' => AppointmentStatus.cancelledByProvider,
        'no_show' => AppointmentStatus.noShow,
        'expired' => AppointmentStatus.expired,
        _ => throw ArgumentError('Unknown appointment status: $raw'),
      };

  bool get isActive =>
      this == AppointmentStatus.pendingPayment ||
      this == AppointmentStatus.confirmed ||
      this == AppointmentStatus.inProgress;
}
