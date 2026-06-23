import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/auth_token_store.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

/// Persists the session locally (secure storage) so it survives app restarts.
/// The token is delegated to [AuthTokenStore] (shared with the interceptor);
/// the user profile is cached alongside it under a separate key.
abstract interface class AuthLocalDataSource {
  Future<void> cacheSession(AuthSessionModel session);
  Future<AuthSessionModel?> readSession();
  Future<void> clear();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({
    required AuthTokenStore tokenStore,
    required FlutterSecureStorage storage,
  })  : _tokenStore = tokenStore,
        _storage = storage;

  final AuthTokenStore _tokenStore;
  final FlutterSecureStorage _storage;

  static const String _userKey = 'drplus.cached_user';

  @override
  Future<void> cacheSession(AuthSessionModel session) async {
    try {
      await _tokenStore.saveToken(session.token);
      await _storage.write(
        key: _userKey,
        value: jsonEncode(session.userModel.toJson()),
      );
    } catch (_) {
      throw const CacheException('Failed to persist the session.');
    }
  }

  @override
  Future<AuthSessionModel?> readSession() async {
    try {
      final token = await _tokenStore.readToken();
      final rawUser = await _storage.read(key: _userKey);
      if (token == null || token.isEmpty || rawUser == null) {
        return null;
      }
      final userJson = (jsonDecode(rawUser) as Map).cast<String, dynamic>();
      return AuthSessionModel(
        token: token,
        user: UserModel.fromJson(userJson),
      );
    } on CacheException {
      rethrow;
    } catch (_) {
      // Corrupt cache — treat as "no session" rather than crashing boot.
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _tokenStore.clearToken();
      await _storage.delete(key: _userKey);
    } catch (_) {
      throw const CacheException('Failed to clear the session.');
    }
  }
}
