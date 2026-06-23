import 'package:dio/dio.dart';

import '../storage/auth_token_store.dart';

/// Attaches the bearer token to every outgoing request when a session exists,
/// and clears a stale token on a 401 so the app can route back to login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStore);

  final AuthTokenStore _tokenStore;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStore.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // The token is invalid/expired — drop it so subsequent boots are clean.
      await _tokenStore.clearToken();
    }
    handler.next(err);
  }
}
