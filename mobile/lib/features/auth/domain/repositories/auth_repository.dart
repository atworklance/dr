import '../../../../core/utils/typedefs.dart';
import '../entities/auth_session.dart';
import '../entities/auth_user.dart';
import '../entities/client_registration.dart';
import '../entities/provider_registration.dart';

/// Domain contract for authentication. Implemented in the data layer; depended
/// upon by the use cases. Keeps the domain free of any networking/storage detail.
abstract interface class AuthRepository {
  /// Registers a new client and returns the established session.
  ResultFuture<AuthSession> registerClient(ClientRegistration registration);

  /// Registers a new provider (pending admin approval) and returns the session.
  ResultFuture<AuthSession> registerProvider(ProviderRegistration registration);

  /// Authenticates with email + password.
  ResultFuture<AuthSession> login({
    required String email,
    required String password,
  });

  /// Fetches the current authenticated profile from the backend.
  ResultFuture<AuthUser> getCurrentUser();

  /// Restores a previously persisted session from local secure storage, or
  /// returns `Right(null)` when none exists.
  ResultFuture<AuthSession?> restoreSession();

  /// Clears the persisted session.
  ResultVoid logout();
}
