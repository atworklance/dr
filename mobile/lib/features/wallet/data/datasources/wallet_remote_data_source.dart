import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/wallet_summary.dart';
import '../models/wallet_summary_model.dart';

abstract interface class WalletRemoteDataSource {
  Future<WalletSummary> getSummary();
  Future<WalletSummary> requestWithdrawal({
    required int amountMinorUnits,
    required String payoutMethod,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<WalletSummary> getSummary() async {
    final response = await _client.get(ApiEndpoints.walletMe);
    return WalletSummaryMapper.fromJson(_data(response));
  }

  @override
  Future<WalletSummary> requestWithdrawal({
    required int amountMinorUnits,
    required String payoutMethod,
  }) async {
    final response = await _client.post(
      ApiEndpoints.walletWithdrawals,
      data: <String, dynamic>{
        'amount': amountMinorUnits,
        'payoutMethod': payoutMethod,
      },
    );
    // The endpoint returns { requestId, wallet: <summary> }.
    final data = _data(response);
    final wallet = (data['wallet'] as Map?)?.cast<String, dynamic>();
    return WalletSummaryMapper.fromJson(wallet ?? data);
  }

  DataMap _data(DataMap response) {
    final data = response['data'];
    if (data is Map) return data.cast<String, dynamic>();
    throw const FormatException('Malformed response: missing "data" object.');
  }
}
