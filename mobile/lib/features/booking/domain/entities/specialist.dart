import 'package:equatable/equatable.dart';

import '../../../../core/entities/consultation_mode.dart';
import '../../../../core/entities/geo_point.dart';
import 'specialist_pricing.dart';

/// A searchable service provider profile (the client-facing view of a Provider).
class Specialist extends Equatable {
  const Specialist({
    required this.id,
    required this.displayName,
    required this.primarySpecialty,
    required this.specialties,
    required this.consultationModes,
    required this.pricing,
    required this.ratingAverage,
    required this.ratingCount,
    required this.isAcceptingNewClients,
    required this.holidayMode,
    required this.totalCompletedAppointments,
    this.headline,
    this.bio,
    this.yearsOfExperience = 0,
    this.languages = const [],
    this.clinicLocation,
    this.clinicAddress,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? headline;
  final String? bio;
  final String primarySpecialty;
  final List<String> specialties;
  final int yearsOfExperience;
  final List<String> languages;
  final List<ConsultationMode> consultationModes;
  final SpecialistPricing pricing;
  final double ratingAverage;
  final int ratingCount;
  final bool isAcceptingNewClients;
  final bool holidayMode;
  final int totalCompletedAppointments;
  final GeoPoint? clinicLocation;
  final String? clinicAddress;
  final String? avatarUrl;

  /// A specialist is bookable when accepting clients and not on holiday.
  bool get isBookable => isAcceptingNewClients && !holidayMode;

  bool get offersOnline => consultationModes.contains(ConsultationMode.online);
  bool get offersClinic => consultationModes.contains(ConsultationMode.clinic);

  @override
  List<Object?> get props => [
        id,
        displayName,
        headline,
        bio,
        primarySpecialty,
        specialties,
        yearsOfExperience,
        languages,
        consultationModes,
        pricing,
        ratingAverage,
        ratingCount,
        isAcceptingNewClients,
        holidayMode,
        totalCompletedAppointments,
        clinicLocation,
        clinicAddress,
        avatarUrl,
      ];
}
