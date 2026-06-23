import '../../../../core/utils/typedefs.dart';
import '../entities/wallet_summary.dart';

/// Domain contract for the provider revenue dashboard.
abstract interface class WalletRepository {
  /// Loads the wallet summary (balances, lifetime stats, recent transactions).
  ResultFuture<WalletSummary> getSummary();

  /// Requests a payout; returns the refreshed summary.
  ResultFuture<WalletSummary> requestWithdrawal({
    required int amountMinorUnits,
    required String payoutMethod,
  });
}
