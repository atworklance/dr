import '../../../../core/entities/paged_result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/booking_request.dart';
import '../../domain/entities/search_filter.dart';
import '../../domain/entities/specialist.dart';
import '../models/appointment_model.dart';
import '../models/specialist_model.dart';

/// Talks to the backend specialist-search and appointment endpoints.
abstract interface class BookingRemoteDataSource {
  Future<PagedResult<Specialist>> searchSpecialists(SearchFilter filter);
  Future<SpecialistModel> getSpecialistById(String id);
  Future<AppointmentModel> bookAppointment(BookingRequest request);
  Future<AppointmentModel> payForAppointment({
    required String appointmentId,
    required String paymentReference,
  });
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  BookingRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<PagedResult<Specialist>> searchSpecialists(SearchFilter filter) async {
    final response = await _client.get(
      ApiEndpoints.providers,
      queryParameters: _searchQuery(filter),
    );

    final rawItems = response['data'];
    final meta = (response['meta'] as Map?)?.cast<String, dynamic>() ?? const {};

    final items = <Specialist>[
      if (rawItems is List)
        for (final item in rawItems)
          SpecialistModel.fromJson((item as Map).cast<String, dynamic>()),
    ];

    return PagedResult<Specialist>(
      items: items,
      total: (meta['total'] as int?) ?? items.length,
      page: (meta['page'] as int?) ?? filter.page,
      limit: (meta['limit'] as int?) ?? filter.limit,
    );
  }

  @override
  Future<SpecialistModel> getSpecialistById(String id) async {
    final response = await _client.get(ApiEndpoints.providerById(id));
    return SpecialistModel.fromJson(_data(response));
  }

  @override
  Future<AppointmentModel> bookAppointment(BookingRequest request) async {
    final response = await _client.post(
      ApiEndpoints.appointments,
      data: <String, dynamic>{
        'providerId': request.providerId,
        'consultationMode': request.mode.value,
        'start': request.start.toUtc().toIso8601String(),
        'end': request.end.toUtc().toIso8601String(),
        if (request.notes != null && request.notes!.isNotEmpty)
          'notes': request.notes,
      },
    );
    return AppointmentModel.fromJson(_data(response));
  }

  @override
  Future<AppointmentModel> payForAppointment({
    required String appointmentId,
    required String paymentReference,
  }) async {
    final response = await _client.post(
      ApiEndpoints.payAppointment(appointmentId),
      data: <String, dynamic>{'paymentReference': paymentReference},
    );
    return AppointmentModel.fromJson(_data(response));
  }

  /// Builds the query string for the search endpoint, omitting absent filters.
  DataMap _searchQuery(SearchFilter filter) {
    return <String, dynamic>{
      if (filter.query != null && filter.query!.isNotEmpty) 'q': filter.query,
      if (filter.specialty != null) 'specialty': filter.specialty,
      if (filter.center != null) ...<String, dynamic>{
        'lng': filter.center!.longitude,
        'lat': filter.center!.latitude,
        if (filter.radiusKm != null) 'radiusKm': filter.radiusKm,
      },
      if (filter.minRating != null) 'minRating': filter.minRating,
      if (filter.mode != null) 'mode': filter.mode!.value,
      'page': filter.page,
      'limit': filter.limit,
    };
  }

  DataMap _data(DataMap response) {
    final data = response['data'];
    if (data is Map) return data.cast<String, dynamic>();
    throw const FormatException('Malformed response: missing "data" object.');
  }
}
