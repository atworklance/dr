import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/typedefs.dart';
import '../models/rtc_credentials_model.dart';

/// Talks to the backend video endpoints.
abstract interface class VideoRemoteDataSource {
  Future<RtcCredentialsModel> getToken(String appointmentId);
  Future<void> startSession(String appointmentId);
  Future<void> endSession(String appointmentId);
}

class VideoRemoteDataSourceImpl implements VideoRemoteDataSource {
  VideoRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<RtcCredentialsModel> getToken(String appointmentId) async {
    final response = await _client.post(ApiEndpoints.videoToken(appointmentId));
    return RtcCredentialsModel.fromJson(_data(response));
  }

  @override
  Future<void> startSession(String appointmentId) async {
    await _client.post(ApiEndpoints.videoStart(appointmentId));
  }

  @override
  Future<void> endSession(String appointmentId) async {
    await _client.post(ApiEndpoints.videoEnd(appointmentId));
  }

  DataMap _data(DataMap response) {
    final data = response['data'];
    if (data is Map) return data.cast<String, dynamic>();
    throw const FormatException('Malformed response: missing "data" object.');
  }
}
