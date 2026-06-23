import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/availability_exception.dart';
import '../../domain/entities/availability_window.dart';
import '../../domain/entities/provider_availability.dart';
import '../models/availability_models.dart';

abstract interface class AvailabilityRemoteDataSource {
  Future<ProviderAvailability> getAvailability();
  Future<List<AvailabilityWindow>> updateWeekly(List<AvailabilityWindow> windows);
  Future<List<AvailabilityException>> upsertException(
    AvailabilityException exception,
  );
  Future<bool> setHolidayMode(bool enabled);
}

class AvailabilityRemoteDataSourceImpl implements AvailabilityRemoteDataSource {
  AvailabilityRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<ProviderAvailability> getAvailability() async {
    final response = await _client.get(ApiEndpoints.availability);
    return AvailabilityMapper.availabilityFromJson(_data(response));
  }

  @override
  Future<List<AvailabilityWindow>> updateWeekly(
    List<AvailabilityWindow> windows,
  ) async {
    final response = await _client.put(
      ApiEndpoints.availabilityWeekly,
      data: <String, dynamic>{
        'weeklyAvailability':
            windows.map(AvailabilityMapper.windowToJson).toList(),
      },
    );
    final data = _data(response);
    final list = (data['weeklyAvailability'] as List?) ?? const [];
    return list
        .map((e) => AvailabilityMapper.windowFromJson(
              (e as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  @override
  Future<List<AvailabilityException>> upsertException(
    AvailabilityException exception,
  ) async {
    final response = await _client.post(
      ApiEndpoints.availabilityExceptions,
      data: AvailabilityMapper.exceptionToJson(exception),
    );
    final data = _data(response);
    final list = (data['availabilityExceptions'] as List?) ?? const [];
    return list
        .map((e) => AvailabilityMapper.exceptionFromJson(
              (e as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  @override
  Future<bool> setHolidayMode(bool enabled) async {
    final response = await _client.patch(
      ApiEndpoints.availabilityHolidayMode,
      data: <String, dynamic>{'holidayMode': enabled},
    );
    final data = _data(response);
    return data['holidayMode'] as bool? ?? enabled;
  }

  DataMap _data(DataMap response) {
    final data = response['data'];
    if (data is Map) return data.cast<String, dynamic>();
    throw const FormatException('Malformed response: missing "data" object.');
  }
}
