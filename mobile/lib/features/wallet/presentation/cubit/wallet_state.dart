part of 'wallet_cubit.dart';

enum WalletStatus { initial, loading, ready, error }

class WalletState extends Equatable {
  const WalletState({
    this.status = WalletStatus.initial,
    this.summary,
    this.isWithdrawing = false,
    this.errorMessage,
    this.actionMessage,
  });

  final WalletStatus status;
  final WalletSummary? summary;
  final bool isWithdrawing;
  final String? errorMessage;

  /// Transient one-shot success message (e.g. withdrawal requested).
  final String? actionMessage;

  bool get isReady => status == WalletStatus.ready && summary != null;

  WalletState copyWith({
    WalletStatus? status,
    WalletSummary? summary,
    bool? isWithdrawing,
    String? errorMessage,
    String? actionMessage,
    bool clearError = false,
    bool clearAction = false,
  }) {
    return WalletState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      isWithdrawing: isWithdrawing ?? this.isWithdrawing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionMessage: clearAction ? null : (actionMessage ?? this.actionMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, summary, isWithdrawing, errorMessage, actionMessage];
}
