import 'package:equatable/equatable.dart';

import 'wallet_transaction.dart';

/// The three balance buckets, in integer minor currency units.
class WalletBalances extends Equatable {
  const WalletBalances({
    required this.available,
    required this.pending,
    required this.escrow,
  });

  final int available;
  final int pending;
  final int escrow;

  @override
  List<Object?> get props => [available, pending, escrow];
}

/// The provider revenue snapshot returned by `GET /wallets/me`.
class WalletSummary extends Equatable {
  const WalletSummary({
    required this.currency,
    required this.balances,
    required this.totalBalance,
    required this.lifetimeEarnings,
    required this.lifetimeWithdrawn,
    required this.pendingWithdrawals,
    required this.transactions,
  });

  final String currency;
  final WalletBalances balances;
  final int totalBalance;
  final int lifetimeEarnings;
  final int lifetimeWithdrawn;
  final int pendingWithdrawals;
  final List<WalletTransaction> transactions;

  @override
  List<Object?> get props => [
        currency,
        balances,
        totalBalance,
        lifetimeEarnings,
        lifetimeWithdrawn,
        pendingWithdrawals,
        transactions,
      ];
}
