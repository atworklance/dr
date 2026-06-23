import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/wallet_summary.dart';
import '../repositories/wallet_repository.dart';

/// Requests a provider payout (withdrawal).
class RequestWithdrawal extends UseCase<WalletSummary, RequestWithdrawalParams> {
  RequestWithdrawal(this._repository);

  final WalletRepository _repository;

  @override
  ResultFuture<WalletSummary> call(RequestWithdrawalParams params) =>
      _repository.requestWithdrawal(
        amountMinorUnits: params.amountMinorUnits,
        payoutMethod: params.payoutMethod,
      );
}

class RequestWithdrawalParams extends Equatable {
  const RequestWithdrawalParams({
    required this.amountMinorUnits,
    required this.payoutMethod,
  });

  final int amountMinorUnits;
  final String payoutMethod;

  @override
  List<Object?> get props => [amountMinorUnits, payoutMethod];
}
