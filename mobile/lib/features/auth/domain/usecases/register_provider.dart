import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/auth_session.dart';
import '../entities/provider_registration.dart';
import '../repositories/auth_repository.dart';

/// Registers a new provider account (pending admin approval) and returns the
/// established session.
class RegisterProvider extends UseCase<AuthSession, ProviderRegistration> {
  RegisterProvider(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<AuthSession> call(ProviderRegistration params) =>
      _repository.registerProvider(params);
}
