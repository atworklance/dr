import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/auth_session.dart';
import 'user_model.dart';

/// Data-layer representation of [AuthSession]. Parses the `{ token, user }`
/// object the backend returns inside its `data` envelope on login/registration.
class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required String token, required UserModel user})
      : super(token: token, user: user);

  factory AuthSessionModel.fromJson(DataMap json) {
    return AuthSessionModel(
      token: json['token'] as String,
      user: UserModel.fromJson((json['user'] as Map).cast<String, dynamic>()),
    );
  }

  UserModel get userModel => user as UserModel;

  DataMap toJson() => <String, dynamic>{
        'token': token,
        'user': userModel.toJson(),
      };
}
