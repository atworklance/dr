import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single source of truth for the persisted JWT access token. Consumed both by
/// the auth local data source (to restore sessions) and the [AuthInterceptor]
/// (to attach the bearer token to outgoing requests).
class AuthTokenStore {
  AuthTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'drplus.access_token';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
