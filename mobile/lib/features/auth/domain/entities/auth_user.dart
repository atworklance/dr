import 'package:equatable/equatable.dart';

import 'user_role.dart';

/// Biological/identity sex recorded on the profile. Mirrors backend `Gender`.
enum Gender {
  male,
  female,
  other,
  undisclosed;

  String get value => name;

  static Gender fromValue(String raw) => Gender.values.firstWhere(
        (g) => g.name == raw,
        orElse: () => Gender.undisclosed,
      );
}

/// Lifecycle state of an account. Mirrors backend `AccountStatus`.
enum AccountStatus {
  pending,
  active,
  suspended,
  deactivated;

  String get value => name;

  static AccountStatus fromValue(String raw) => AccountStatus.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => AccountStatus.pending,
      );
}

/// The authenticated user's public profile (never contains the password hash).
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.status,
    required this.gender,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.preferredLocale,
    this.phone,
    this.avatarUrl,
    this.providerProfileId,
    this.walletId,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final UserRole role;
  final AccountStatus status;
  final Gender gender;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String preferredLocale;
  final String? avatarUrl;
  final String? providerProfileId;
  final String? walletId;

  String get fullName => '$firstName $lastName'.trim();

  bool get isProvider => role == UserRole.provider;
  bool get isClient => role == UserRole.client;
  bool get isActive => status == AccountStatus.active;

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        phone,
        role,
        status,
        gender,
        isEmailVerified,
        isPhoneVerified,
        preferredLocale,
        avatarUrl,
        providerProfileId,
        walletId,
      ];
}
