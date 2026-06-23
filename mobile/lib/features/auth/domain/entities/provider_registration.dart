import 'package:equatable/equatable.dart';

import '../../../../core/entities/consultation_mode.dart';
import '../../../../core/entities/geo_point.dart';
import 'auth_user.dart';

/// Strongly-typed payload for provider self-registration. Maps directly to the
/// backend `POST /auth/register/provider` request body, including the nested
/// pricing block and clinic location.
class ProviderRegistration extends Equatable {
  const ProviderRegistration({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.displayName,
    required this.primarySpecialty,
    required this.specialties,
    required this.consultationModes,
    required this.onlineFee,
    required this.clinicFee,
    required this.currency,
    required this.sessionDurationMinutes,
    this.phone,
    this.gender,
    this.headline,
    this.bio,
    this.yearsOfExperience,
    this.languages,
    this.clinicLocation,
    this.clinicAddress,
    this.preferredLocale,
  });

  // Account fields
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? phone;
  final Gender? gender;
  final String? preferredLocale;

  // Professional profile
  final String displayName;
  final String? headline;
  final String? bio;
  final String primarySpecialty;
  final List<String> specialties;
  final int? yearsOfExperience;
  final List<String>? languages;
  final List<ConsultationMode> consultationModes;

  // Pricing (fees in integer minor currency units)
  final int onlineFee;
  final int clinicFee;
  final String currency;
  final int sessionDurationMinutes;

  // Clinic location (required by the backend when offering clinic consults)
  final GeoPoint? clinicLocation;
  final String? clinicAddress;

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        email,
        password,
        phone,
        gender,
        preferredLocale,
        displayName,
        headline,
        bio,
        primarySpecialty,
        specialties,
        yearsOfExperience,
        languages,
        consultationModes,
        onlineFee,
        clinicFee,
        currency,
        sessionDurationMinutes,
        clinicLocation,
        clinicAddress,
      ];
}
