import 'package:equatable/equatable.dart';

import '../../../../core/entities/geo_point.dart';
import 'auth_user.dart';

/// Strongly-typed payload for client self-registration. Maps directly to the
/// backend `POST /auth/register/client` request body.
class ClientRegistration extends Equatable {
  const ClientRegistration({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.location,
    this.preferredLocale,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? phone;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final GeoPoint? location;
  final String? preferredLocale;

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        email,
        password,
        phone,
        gender,
        dateOfBirth,
        location,
        preferredLocale,
      ];
}
