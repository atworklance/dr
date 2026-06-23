import 'package:equatable/equatable.dart';

/// A geographic coordinate shared across features (user location, clinic
/// location, search centre). Mirrors the backend GeoJSON `[longitude, latitude]`
/// ordering.
class GeoPoint extends Equatable {
  const GeoPoint({required this.longitude, required this.latitude});

  final double longitude;
  final double latitude;

  @override
  List<Object?> get props => [longitude, latitude];
}
