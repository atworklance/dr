import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/auth_session.dart';
import '../entities/client_registration.dart';
import '../repositories/auth_repository.dart';

/// Registers a new client account and returns the established session.
class RegisterClient extends UseCase<AuthSession, ClientRegistration> {
  RegisterClient(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<AuthSession> call(ClientRegistration params) =>
      _repository.registerClient(params);
}
