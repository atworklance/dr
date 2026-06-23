import 'package:equatable/equatable.dart';

import 'auth_user.dart';

/// An authenticated session: the JWT access token plus the resolved profile.
class AuthSession extends Equatable {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;

  @override
  List<Object?> get props => [token, user];
}
