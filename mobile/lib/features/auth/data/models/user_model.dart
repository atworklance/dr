import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/user_role.dart';

/// Data-layer representation of [AuthUser]. Knows how to (de)serialise the
/// backend's public user JSON envelope.
class UserModel extends AuthUser {
  const UserModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.role,
    required super.status,
    required super.gender,
    required super.isEmailVerified,
    required super.isPhoneVerified,
    required super.preferredLocale,
    super.phone,
    super.avatarUrl,
    super.providerProfileId,
    super.walletId,
  });

  factory UserModel.fromJson(DataMap json) {
    return UserModel(
      id: (json['id'] ?? json['_id']).toString(),
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: UserRole.fromValue(json['role'] as String? ?? 'client'),
      status: AccountStatus.fromValue(json['status'] as String? ?? 'pending'),
      gender: Gender.fromValue(json['gender'] as String? ?? 'undisclosed'),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      preferredLocale: json['preferredLocale'] as String? ?? 'en',
      avatarUrl: json['avatarUrl'] as String?,
      providerProfileId: _idOf(json['providerProfile']),
      walletId: _idOf(json['wallet']),
    );
  }

  DataMap toJson() {
    return <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role.value,
      'status': status.value,
      'gender': gender.value,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'preferredLocale': preferredLocale,
      'avatarUrl': avatarUrl,
      'providerProfile': providerProfileId,
      'wallet': walletId,
    };
  }

  /// A ref field may arrive as a raw id string or a populated object.
  static String? _idOf(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return (value['id'] ?? value['_id'])?.toString();
    return value.toString();
  }
}
