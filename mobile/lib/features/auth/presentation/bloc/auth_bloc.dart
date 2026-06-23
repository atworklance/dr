import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/client_registration.dart';
import '../../domain/entities/provider_registration.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';
import '../../domain/usecases/register_client.dart';
import '../../domain/usecases/register_provider.dart';
import '../../domain/usecases/restore_session.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Orchestrates the authentication lifecycle: session restoration, login,
/// client/provider registration, and logout. Holds no business logic itself —
/// it delegates to use cases and folds their `Either` results into [AuthState].
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required RestoreSession restoreSession,
    required LoginUser loginUser,
    required RegisterClient registerClient,
    required RegisterProvider registerProvider,
    required LogoutUser logoutUser,
  })  : _restoreSession = restoreSession,
        _loginUser = loginUser,
        _registerClient = registerClient,
        _registerProvider = registerProvider,
        _logoutUser = logoutUser,
        super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthClientRegisterRequested>(_onClientRegisterRequested);
    on<AuthProviderRegisterRequested>(_onProviderRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final RestoreSession _restoreSession;
  final LoginUser _loginUser;
  final RegisterClient _registerClient;
  final RegisterProvider _registerProvider;
  final LogoutUser _logoutUser;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearFailure: true));
    final result = await _restoreSession();
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        clearSession: true,
      )),
      (session) => emit(
        session == null
            ? state.copyWith(status: AuthStatus.unauthenticated, clearSession: true)
            : state.copyWith(status: AuthStatus.authenticated, session: session),
      ),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearFailure: true));
    final result = await _loginUser(
      LoginParams(email: event.email, password: event.password),
    );
    _emitSessionResult(result, emit);
  }

  Future<void> _onClientRegisterRequested(
    AuthClientRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearFailure: true));
    final result = await _registerClient(event.registration);
    _emitSessionResult(result, emit);
  }

  Future<void> _onProviderRegisterRequested(
    AuthProviderRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearFailure: true));
    final result = await _registerProvider(event.registration);
    _emitSessionResult(result, emit);
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUser();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  /// Shared folding for the three session-producing flows.
  void _emitSessionResult(
    Either<Failure, AuthSession> result,
    Emitter<AuthState> emit,
  ) {
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        failure: failure,
        clearSession: true,
      )),
      (session) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        session: session,
        clearFailure: true,
      )),
    );
  }
}
