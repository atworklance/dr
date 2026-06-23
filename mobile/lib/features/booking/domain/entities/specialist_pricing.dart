import 'package:equatable/equatable.dart';

/// A specialist's consultation pricing. Fees are integer minor currency units
/// (e.g. cents) to mirror the backend and avoid floating-point drift.
class SpecialistPricing extends Equatable {
  const SpecialistPricing({
    required this.onlineFee,
    required this.clinicFee,
    required this.currency,
    required this.sessionDurationMinutes,
  });

  final int onlineFee;
  final int clinicFee;
  final String currency;
  final int sessionDurationMinutes;

  /// Major-unit representation for display (e.g. 4500 -> 45.00).
  double get onlineFeeMajor => onlineFee / 100;
  double get clinicFeeMajor => clinicFee / 100;

  @override
  List<Object?> get props => [
        onlineFee,
        clinicFee,
        currency,
        sessionDurationMinutes,
      ];
}
