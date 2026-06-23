/// Settlement state of an appointment's payment. Mirrors backend `PaymentStatus`.
enum PaymentStatus {
  unpaid,
  authorized,
  inEscrow,
  released,
  refunded,
  failed;

  String get value => switch (this) {
        PaymentStatus.unpaid => 'unpaid',
        PaymentStatus.authorized => 'authorized',
        PaymentStatus.inEscrow => 'in_escrow',
        PaymentStatus.released => 'released',
        PaymentStatus.refunded => 'refunded',
        PaymentStatus.failed => 'failed',
      };

  static PaymentStatus fromValue(String raw) => switch (raw) {
        'unpaid' => PaymentStatus.unpaid,
        'authorized' => PaymentStatus.authorized,
        'in_escrow' => PaymentStatus.inEscrow,
        'released' => PaymentStatus.released,
        'refunded' => PaymentStatus.refunded,
        'failed' => PaymentStatus.failed,
        _ => throw ArgumentError('Unknown payment status: $raw'),
      };
}
