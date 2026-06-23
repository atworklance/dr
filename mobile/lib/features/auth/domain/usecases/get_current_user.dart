import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Fetches the freshest copy of the authenticated user's profile.
class GetCurrentUser extends UseCaseWithoutParams<AuthUser> {
  GetCurrentUser(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<AuthUser> call() => _repository.getCurrentUser();
}
