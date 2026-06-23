import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/wallet_summary.dart';
import '../repositories/wallet_repository.dart';

/// Loads the provider's wallet summary.
class GetWalletSummary extends UseCaseWithoutParams<WalletSummary> {
  GetWalletSummary(this._repository);

  final WalletRepository _repository;

  @override
  ResultFuture<WalletSummary> call() => _repository.getSummary();
}
