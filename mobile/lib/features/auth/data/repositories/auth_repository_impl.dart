import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/client_registration.dart';
import '../../domain/entities/provider_registration.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

/// Coordinates the remote and local auth data sources and translates data-layer
/// exceptions into domain [Failure]s. Successful auth flows are cached so the
/// session can be restored on next launch.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _local = local,
        _networkInfo = networkInfo;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final NetworkInfo _networkInfo;

  @override
  ResultFuture<AuthSession> registerClient(ClientRegistration registration) {
    return guardRemote(_networkInfo, () async {
      final session = await _remote.registerClient(registration);
      await _local.cacheSession(session);
      return session;
    });
  }

  @override
  ResultFuture<AuthSession> registerProvider(
    ProviderRegistration registration,
  ) {
    return guardRemote(_networkInfo, () async {
      final session = await _remote.registerProvider(registration);
      await _local.cacheSession(session);
      return session;
    });
  }

  @override
  ResultFuture<AuthSession> login({
    required String email,
    required String password,
  }) {
    return guardRemote(_networkInfo, () async {
      final session = await _remote.login(email: email, password: password);
      await _local.cacheSession(session);
      return session;
    });
  }

  @override
  ResultFuture<AuthUser> getCurrentUser() {
    return guardRemote(_networkInfo, () => _remote.getCurrentUser());
  }

  @override
  ResultFuture<AuthSession?> restoreSession() {
    return guardLocal<AuthSession?>(() => _local.readSession());
  }

  @override
  ResultVoid logout() async {
    try {
      await _local.clear();
      return const Right(null);
    } catch (_) {
      return const Left(CacheFailure('Failed to clear the session.'));
    }
  }
}
