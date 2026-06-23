part of 'auth_bloc.dart';

/// Events accepted by [AuthBloc].
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Emitted once at startup to restore any persisted session.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Email + password login.
class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Client self-registration.
class AuthClientRegisterRequested extends AuthEvent {
  const AuthClientRegisterRequested(this.registration);

  final ClientRegistration registration;

  @override
  List<Object?> get props => [registration];
}

/// Provider self-registration.
class AuthProviderRegisterRequested extends AuthEvent {
  const AuthProviderRegisterRequested(this.registration);

  final ProviderRegistration registration;

  @override
  List<Object?> get props => [registration];
}

/// Clears the session and returns to the unauthenticated state.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
