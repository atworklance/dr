import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/wallet_summary.dart';
import '../cubit/wallet_cubit.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/withdrawal_sheet.dart';

/// Provider revenue dashboard: available/pending/escrow balances, lifetime
/// stats, the earnings log, and withdrawal requests. Self-provides [WalletCubit].
class RevenueDashboardPage extends StatelessWidget {
  const RevenueDashboardPage({super.key, this.appBarActions});

  final List<Widget>? appBarActions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WalletCubit>(
      create: (_) => sl<WalletCubit>()..load(),
      child: _DashboardView(appBarActions: appBarActions),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({this.appBarActions});

  final List<Widget>? appBarActions;

  Future<void> _startWithdrawal(BuildContext context, WalletSummary summary) async {
    final request = await showWithdrawalSheet(
      context,
      availableMinorUnits: summary.balances.available,
      currency: summary.currency,
    );
    if (request == null || !context.mounted) return;
    await context.read<WalletCubit>().requestWithdrawal(
          amountMinorUnits: request.amountMinorUnits,
          payoutMethod: request.payoutMethod,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings'), actions: appBarActions),
      body: BlocConsumer<WalletCubit, WalletState>(
        listenWhen: (p, c) =>
            p.errorMessage != c.errorMessage ||
            p.actionMessage != c.actionMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppSnackBar.showError(context, state.errorMessage!);
          } else if (state.actionMessage != null) {
            AppSnackBar.showSuccess(context, state.actionMessage!);
          }
        },
        builder: (context, state) {
          if (state.status == WalletStatus.loading ||
              state.status == WalletStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (!state.isReady) {
            return _ErrorRetry(
              message: state.errorMessage ?? 'Could not load your wallet.',
              onRetry: () => context.read<WalletCubit>().load(),
            );
          }

          final summary = state.summary!;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<WalletCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                _AvailableCard(
                  summary: summary,
                  busy: state.isWithdrawing,
                  onWithdraw: () => _startWithdrawal(context, summary),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _MiniBalanceCard(
                        label: 'Pending',
                        icon: Icons.hourglass_bottom_rounded,
                        amount: Formatters.money(
                          summary.balances.pending,
                          summary.currency,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _MiniBalanceCard(
                        label: 'In escrow',
                        icon: Icons.lock_clock_rounded,
                        amount: Formatters.money(
                          summary.balances.escrow,
                          summary.currency,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _LifetimeRow(summary: summary),
                if (summary.pendingWithdrawals > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  _PendingWithdrawalsBanner(count: summary.pendingWithdrawals),
                ],
                const SizedBox(height: AppSpacing.xl),
                const _SectionHeader('Earnings log'),
                if (summary.transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Text(
                      'No transactions yet.',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  )
                else
                  ...summary.transactions
                      .map((t) => TransactionTile(transaction: t)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AvailableCard extends StatelessWidget {
  const _AvailableCard({
    required this.summary,
    required this.busy,
    required this.onWithdraw,
  });

  final WalletSummary summary;
  final bool busy;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final canWithdraw = summary.balances.available > 0 && !busy;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available balance',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            Formatters.money(summary.balances.available, summary.currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.white60,
              ),
              onPressed: canWithdraw ? onWithdraw : null,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.account_balance_wallet_rounded, size: 20),
              label: const Text('Withdraw funds'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBalanceCard extends StatelessWidget {
  const _MiniBalanceCard({
    required this.label,
    required this.icon,
    required this.amount,
  });

  final String label;
  final IconData icon;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifetimeRow extends StatelessWidget {
  const _LifetimeRow({required this.summary});

  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LifetimeStat(
              label: 'Lifetime earned',
              value: Formatters.money(summary.lifetimeEarnings, summary.currency),
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(
            child: _LifetimeStat(
              label: 'Lifetime withdrawn',
              value:
                  Formatters.money(summary.lifetimeWithdrawn, summary.currency),
            ),
          ),
        ],
      ),
    );
  }
}

class _LifetimeStat extends StatelessWidget {
  const _LifetimeStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _PendingWithdrawalsBanner extends StatelessWidget {
  const _PendingWithdrawalsBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.star.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_send_rounded, size: 20, color: AppColors.star),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '$count withdrawal request${count == 1 ? '' : 's'} awaiting settlement',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
