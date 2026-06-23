import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction over device connectivity so repositories can fail fast with a
/// [NetworkFailure] instead of waiting on a doomed request.
abstract interface class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}
