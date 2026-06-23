import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Restores a persisted session at app start; resolves to `null` when the user
/// has never logged in or previously logged out.
class RestoreSession extends UseCaseWithoutParams<AuthSession?> {
  RestoreSession(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<AuthSession?> call() => _repository.restoreSession();
}
