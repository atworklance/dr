import '../../../../core/entities/consultation_mode.dart';
import '../../../../core/utils/json_mappers.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/specialist.dart';
import '../../domain/entities/specialist_pricing.dart';

/// Data-layer representation of [Specialist]. Parses the backend Provider JSON.
class SpecialistModel extends Specialist {
  const SpecialistModel({
    required super.id,
    required super.displayName,
    required super.primarySpecialty,
    required super.specialties,
    required super.consultationModes,
    required super.pricing,
    required super.ratingAverage,
    required super.ratingCount,
    required super.isAcceptingNewClients,
    required super.holidayMode,
    required super.totalCompletedAppointments,
    super.headline,
    super.bio,
    super.yearsOfExperience,
    super.languages,
    super.clinicLocation,
    super.clinicAddress,
    super.avatarUrl,
  });

  factory SpecialistModel.fromJson(DataMap json) {
    final rating = (json['rating'] as Map?)?.cast<String, dynamic>() ?? const {};
    final pricingJson =
        (json['pricing'] as Map?)?.cast<String, dynamic>() ?? const {};

    return SpecialistModel(
      id: (json['id'] ?? json['_id']).toString(),
      displayName: json['displayName'] as String? ?? '',
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
      primarySpecialty: json['primarySpecialty'] as String? ?? '',
      specialties: _stringList(json['specialties']),
      yearsOfExperience: intFromJson(json['yearsOfExperience']),
      languages: _stringList(json['languages']),
      consultationModes: _modeList(json['consultationModes']),
      pricing: _pricingFromJson(pricingJson),
      ratingAverage: doubleFromJson(rating['average']),
      ratingCount: intFromJson(rating['count']),
      isAcceptingNewClients: json['isAcceptingNewClients'] as bool? ?? false,
      holidayMode: json['holidayMode'] as bool? ?? false,
      totalCompletedAppointments:
          intFromJson(json['totalCompletedAppointments']),
      clinicLocation: geoPointFromJson(json['clinicLocation']),
      clinicAddress: json['clinicAddress'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  static SpecialistPricing _pricingFromJson(DataMap json) {
    return SpecialistPricing(
      onlineFee: intFromJson(json['onlineFee']),
      clinicFee: intFromJson(json['clinicFee']),
      currency: json['currency'] as String? ?? 'USD',
      sessionDurationMinutes:
          intFromJson(json['sessionDurationMinutes'], fallback: 30),
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList(growable: false);
    }
    return const [];
  }

  static List<ConsultationMode> _modeList(Object? value) {
    if (value is List) {
      return value
          .map((e) => ConsultationMode.fromValue(e.toString()))
          .toList(growable: false);
    }
    return const [];
  }
}
