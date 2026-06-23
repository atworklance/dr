import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/wallet_transaction.dart';

/// A single ledger row in the earnings log.
class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, super.key});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final inflow = transaction.isInflow;
    final amount = Formatters.money(transaction.amount.abs(), transaction.currency);
    final sign = inflow ? '+' : '−';
    final amountColor = inflow ? AppColors.success : AppColors.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconColor(transaction.type).withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(_icon(transaction.type),
                size: 20, color: _iconColor(transaction.type)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(transaction.type),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.fullDate(transaction.createdAt),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign$amount',
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _StatusChip(status: transaction.status),
            ],
          ),
        ],
      ),
    );
  }

  String _title(WalletTransactionType type) => switch (type) {
        WalletTransactionType.credit => 'Payment received',
        WalletTransactionType.escrowHold => 'Held in escrow',
        WalletTransactionType.escrowRelease => 'Escrow released',
        WalletTransactionType.refund => 'Refund',
        WalletTransactionType.withdrawal => 'Withdrawal',
        WalletTransactionType.commission => 'Platform commission',
        WalletTransactionType.debit => 'Debit',
        WalletTransactionType.adjustment => 'Adjustment',
        WalletTransactionType.unknown => 'Transaction',
      };

  IconData _icon(WalletTransactionType type) => switch (type) {
        WalletTransactionType.withdrawal => Icons.account_balance_rounded,
        WalletTransactionType.escrowHold => Icons.lock_clock_rounded,
        WalletTransactionType.escrowRelease => Icons.lock_open_rounded,
        WalletTransactionType.refund => Icons.undo_rounded,
        WalletTransactionType.commission => Icons.percent_rounded,
        _ => Icons.payments_rounded,
      };

  Color _iconColor(WalletTransactionType type) => switch (type) {
        WalletTransactionType.withdrawal => AppColors.primary,
        WalletTransactionType.refund => AppColors.danger,
        WalletTransactionType.commission => AppColors.textSecondary,
        _ => AppColors.success,
      };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final WalletTransactionStatus status;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (status) {
      WalletTransactionStatus.settled => ('Settled', AppColors.success),
      WalletTransactionStatus.pending => ('Pending', AppColors.star),
      WalletTransactionStatus.failed => ('Failed', AppColors.danger),
      WalletTransactionStatus.reversed => ('Reversed', AppColors.textTertiary),
      WalletTransactionStatus.unknown => ('—', AppColors.textTertiary),
    };
    return Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    );
  }
}
