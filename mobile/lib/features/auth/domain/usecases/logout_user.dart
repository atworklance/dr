import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/auth_repository.dart';

/// Clears the locally persisted session.
class LogoutUser extends UseCaseWithoutParams<void> {
  LogoutUser(this._repository);

  final AuthRepository _repository;

  @override
  ResultVoid call() => _repository.logout();
}
