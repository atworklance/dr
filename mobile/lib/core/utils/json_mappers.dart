import '../entities/geo_point.dart';
import 'typedefs.dart';

/// Shared JSON <-> value-object mappers used by data-layer models so the
/// translation logic lives in exactly one place.

/// Parses a backend GeoJSON Point object into a [GeoPoint], or null.
GeoPoint? geoPointFromJson(Object? json) {
  if (json is! Map) return null;
  final coordinates = json['coordinates'];
  if (coordinates is! List || coordinates.length != 2) return null;
  final lng = _toDouble(coordinates[0]);
  final lat = _toDouble(coordinates[1]);
  if (lng == null || lat == null) return null;
  return GeoPoint(longitude: lng, latitude: lat);
}

/// Serialises a [GeoPoint] into the backend GeoJSON Point shape, or null.
DataMap? geoPointToJson(GeoPoint? point) {
  if (point == null) return null;
  return <String, dynamic>{
    'type': 'Point',
    'coordinates': [point.longitude, point.latitude],
  };
}

/// Defensive numeric coercion (backend may emit ints or doubles).
double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Parses an ISO-8601 date string into a [DateTime] (UTC-aware), or null.
DateTime? dateTimeFromIso(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}

/// Coerces a backend numeric field to int (minor currency units, counts).
int intFromJson(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Coerces a backend numeric field to double (ratings).
double doubleFromJson(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
