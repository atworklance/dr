import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/wallet_summary.dart';
import '../../domain/usecases/get_wallet_summary.dart';
import '../../domain/usecases/request_withdrawal.dart';

part 'wallet_state.dart';

/// Drives the revenue dashboard: loads the wallet summary and submits payout
/// (withdrawal) requests, refreshing the summary on success.
class WalletCubit extends Cubit<WalletState> {
  WalletCubit({
    required GetWalletSummary getWalletSummary,
    required RequestWithdrawal requestWithdrawal,
  })  : _getWalletSummary = getWalletSummary,
        _requestWithdrawal = requestWithdrawal,
        super(const WalletState());

  final GetWalletSummary _getWalletSummary;
  final RequestWithdrawal _requestWithdrawal;

  Future<void> load() async {
    emit(state.copyWith(status: WalletStatus.loading, clearError: true));
    final result = await _getWalletSummary();
    result.fold(
      (failure) => emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: failure.message,
      )),
      (summary) => emit(state.copyWith(
        status: WalletStatus.ready,
        summary: summary,
        clearError: true,
      )),
    );
  }

  Future<void> requestWithdrawal({
    required int amountMinorUnits,
    required String payoutMethod,
  }) async {
    if (state.isWithdrawing) return;
    emit(state.copyWith(isWithdrawing: true, clearError: true, clearAction: true));

    final result = await _requestWithdrawal(
      RequestWithdrawalParams(
        amountMinorUnits: amountMinorUnits,
        payoutMethod: payoutMethod,
      ),
    );
    result.fold(
      (failure) => emit(state.copyWith(
        isWithdrawing: false,
        errorMessage: failure.message,
      )),
      (summary) => emit(state.copyWith(
        isWithdrawing: false,
        summary: summary,
        actionMessage: 'Withdrawal requested.',
      )),
    );
  }
}
