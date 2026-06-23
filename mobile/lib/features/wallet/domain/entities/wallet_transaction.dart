import 'package:equatable/equatable.dart';

/// Ledger movement classification, mirroring the backend `WalletTxnType`.
enum WalletTransactionType {
  credit,
  debit,
  escrowHold,
  escrowRelease,
  refund,
  withdrawal,
  commission,
  adjustment,
  unknown;

  static WalletTransactionType fromValue(String raw) => switch (raw) {
        'credit' => WalletTransactionType.credit,
        'debit' => WalletTransactionType.debit,
        'escrow_hold' => WalletTransactionType.escrowHold,
        'escrow_release' => WalletTransactionType.escrowRelease,
        'refund' => WalletTransactionType.refund,
        'withdrawal' => WalletTransactionType.withdrawal,
        'commission' => WalletTransactionType.commission,
        'adjustment' => WalletTransactionType.adjustment,
        _ => WalletTransactionType.unknown,
      };
}

/// Settlement state of a ledger movement, mirroring `WalletTxnStatus`.
enum WalletTransactionStatus {
  pending,
  settled,
  failed,
  reversed,
  unknown;

  static WalletTransactionStatus fromValue(String raw) => switch (raw) {
        'pending' => WalletTransactionStatus.pending,
        'settled' => WalletTransactionStatus.settled,
        'failed' => WalletTransactionStatus.failed,
        'reversed' => WalletTransactionStatus.reversed,
        _ => WalletTransactionStatus.unknown,
      };
}

/// A single entry in the wallet ledger. [amount] is signed integer minor units.
class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
    this.description,
    this.reference,
  });

  final WalletTransactionType type;
  final WalletTransactionStatus status;
  final int amount;
  final String currency;
  final DateTime createdAt;
  final String? description;
  final String? reference;

  bool get isInflow => amount >= 0;

  @override
  List<Object?> get props =>
      [type, status, amount, currency, createdAt, description, reference];
}
