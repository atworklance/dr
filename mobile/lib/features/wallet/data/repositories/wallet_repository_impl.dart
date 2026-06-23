import '../../../../core/network/network_info.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({
    required WalletRemoteDataSource remote,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _networkInfo = networkInfo;

  final WalletRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<WalletSummary> getSummary() {
    return guardRemote(_networkInfo, () => _remote.getSummary());
  }

  @override
  ResultFuture<WalletSummary> requestWithdrawal({
    required int amountMinorUnits,
    required String payoutMethod,
  }) {
    return guardRemote(
      _networkInfo,
      () => _remote.requestWithdrawal(
        amountMinorUnits: amountMinorUnits,
        payoutMethod: payoutMethod,
      ),
    );
  }
}
