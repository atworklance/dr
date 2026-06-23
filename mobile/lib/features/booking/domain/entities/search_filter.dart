import 'package:equatable/equatable.dart';

import '../../../../core/entities/consultation_mode.dart';
import '../../../../core/entities/geo_point.dart';

/// Immutable search criteria for the specialist directory. Combines free-text,
/// specialty, proximity, rating, and consultation-mode filters with pagination.
class SearchFilter extends Equatable {
  const SearchFilter({
    this.query,
    this.specialty,
    this.center,
    this.radiusKm,
    this.minRating,
    this.mode,
    this.page = 1,
    this.limit = 20,
  });

  /// Free-text search across name/headline/bio.
  final String? query;

  /// Exact specialty slug filter.
  final String? specialty;

  /// Centre point for proximity search.
  final GeoPoint? center;

  /// Search radius in kilometres (requires [center]).
  final double? radiusKm;

  /// Minimum average rating (0–5).
  final double? minRating;

  /// Consultation mode filter.
  final ConsultationMode? mode;

  final int page;
  final int limit;

  /// Returns a copy advanced to the next page (for infinite scrolling).
  SearchFilter nextPage() => copyWith(page: page + 1);

  /// Returns a copy reset to the first page (when criteria change).
  SearchFilter firstPage() => copyWith(page: 1);

  SearchFilter copyWith({
    String? query,
    String? specialty,
    GeoPoint? center,
    double? radiusKm,
    double? minRating,
    ConsultationMode? mode,
    int? page,
    int? limit,
    bool clearQuery = false,
    bool clearSpecialty = false,
    bool clearCenter = false,
    bool clearMinRating = false,
    bool clearMode = false,
  }) {
    return SearchFilter(
      query: clearQuery ? null : (query ?? this.query),
      specialty: clearSpecialty ? null : (specialty ?? this.specialty),
      center: clearCenter ? null : (center ?? this.center),
      radiusKm: clearCenter ? null : (radiusKm ?? this.radiusKm),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      mode: clearMode ? null : (mode ?? this.mode),
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [
        query,
        specialty,
        center,
        radiusKm,
        minRating,
        mode,
        page,
        limit,
      ];
}
