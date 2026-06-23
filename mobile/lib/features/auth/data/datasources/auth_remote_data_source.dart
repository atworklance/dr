import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/json_mappers.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/client_registration.dart';
import '../../domain/entities/provider_registration.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

/// Talks to the backend auth endpoints. Throws the data-layer exceptions
/// produced by [ApiClient]; never returns a [Failure] (that is the repository's
/// responsibility).
abstract interface class AuthRemoteDataSource {
  Future<AuthSessionModel> registerClient(ClientRegistration registration);
  Future<AuthSessionModel> registerProvider(ProviderRegistration registration);
  Future<AuthSessionModel> login({required String email, required String password});
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<AuthSessionModel> registerClient(ClientRegistration registration) async {
    final response = await _client.post(
      ApiEndpoints.registerClient,
      data: _clientBody(registration),
    );
    return AuthSessionModel.fromJson(_data(response));
  }

  @override
  Future<AuthSessionModel> registerProvider(
    ProviderRegistration registration,
  ) async {
    final response = await _client.post(
      ApiEndpoints.registerProvider,
      data: _providerBody(registration),
    );
    return AuthSessionModel.fromJson(_data(response));
  }

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.login,
      data: <String, dynamic>{'email': email, 'password': password},
    );
    return AuthSessionModel.fromJson(_data(response));
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _client.get(ApiEndpoints.me);
    return UserModel.fromJson(_data(response));
  }

  /// Unwraps the backend `{ success, data }` envelope.
  DataMap _data(DataMap response) {
    final data = response['data'];
    if (data is Map) return data.cast<String, dynamic>();
    throw const FormatException('Malformed response: missing "data" object.');
  }

  DataMap _clientBody(ClientRegistration r) {
    return <String, dynamic>{
      'firstName': r.firstName,
      'lastName': r.lastName,
      'email': r.email,
      'password': r.password,
      if (r.phone != null) 'phone': r.phone,
      if (r.gender != null) 'gender': r.gender!.value,
      if (r.dateOfBirth != null)
        'dateOfBirth': r.dateOfBirth!.toUtc().toIso8601String(),
      if (r.location != null) 'location': geoPointToJson(r.location),
      if (r.preferredLocale != null) 'preferredLocale': r.preferredLocale,
    };
  }

  DataMap _providerBody(ProviderRegistration r) {
    return <String, dynamic>{
      'firstName': r.firstName,
      'lastName': r.lastName,
      'email': r.email,
      'password': r.password,
      if (r.phone != null) 'phone': r.phone,
      if (r.gender != null) 'gender': r.gender!.value,
      if (r.preferredLocale != null) 'preferredLocale': r.preferredLocale,
      'displayName': r.displayName,
      if (r.headline != null) 'headline': r.headline,
      if (r.bio != null) 'bio': r.bio,
      'primarySpecialty': r.primarySpecialty,
      'specialties': r.specialties,
      if (r.yearsOfExperience != null) 'yearsOfExperience': r.yearsOfExperience,
      if (r.languages != null) 'languages': r.languages,
      'consultationModes': r.consultationModes.map((m) => m.value).toList(),
      'pricing': <String, dynamic>{
        'onlineFee': r.onlineFee,
        'clinicFee': r.clinicFee,
        'currency': r.currency,
        'sessionDurationMinutes': r.sessionDurationMinutes,
      },
      if (r.clinicLocation != null)
        'clinicLocation': geoPointToJson(r.clinicLocation),
      if (r.clinicAddress != null) 'clinicAddress': r.clinicAddress,
    };
  }
}
