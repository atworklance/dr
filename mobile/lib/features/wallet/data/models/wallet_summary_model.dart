import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';

/// Parses the backend wallet summary payload.
abstract final class WalletSummaryMapper {
  static WalletSummary fromJson(DataMap json) {
    final balances =
        (json['balances'] as Map?)?.cast<String, dynamic>() ?? const {};
    final txns = (json['recentTransactions'] as List?) ?? const [];

    return WalletSummary(
      currency: json['currency'] as String? ?? 'USD',
      balances: WalletBalances(
        available: _int(balances['available']),
        pending: _int(balances['pending']),
        escrow: _int(balances['escrow']),
      ),
      totalBalance: _int(json['totalBalance']),
      lifetimeEarnings: _int(json['lifetimeEarnings']),
      lifetimeWithdrawn: _int(json['lifetimeWithdrawn']),
      pendingWithdrawals: _int(json['pendingWithdrawals']),
      transactions: txns
          .whereType<Map>()
          .map((e) => _txnFromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  static WalletTransaction _txnFromJson(DataMap json) {
    return WalletTransaction(
      type: WalletTransactionType.fromValue(json['type'] as String? ?? ''),
      status: WalletTransactionStatus.fromValue(json['status'] as String? ?? ''),
      amount: _int(json['amount']),
      currency: json['currency'] as String? ?? 'USD',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      description: json['description'] as String?,
      reference: json['reference'] as String?,
    );
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
