part of 'auth_bloc.dart';

enum AuthStatus {
  /// Startup; the session is being restored.
  unknown,

  /// A request (login/register/restore) is in flight.
  authenticating,

  /// A valid session exists.
  authenticated,

  /// No session exists.
  unauthenticated,
}

/// Single immutable state for [AuthBloc]. [failure] is transient — it is set on
/// a failed attempt and carried alongside the prior status so the UI can show
/// an error without losing context.
class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.session,
    this.failure,
  });

  const AuthState.unknown() : this();

  final AuthStatus status;
  final AuthSession? session;
  final Failure? failure;

  AuthUser? get user => session?.user;
  bool get isAuthenticated => status == AuthStatus.authenticated && session != null;
  bool get isBusy => status == AuthStatus.authenticating;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    Failure? failure,
    bool clearFailure = false,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, session, failure];
}
