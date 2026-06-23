import 'package:dio/dio.dart';

import '../error/exceptions.dart';
import '../utils/typedefs.dart';

/// Thin, typed wrapper over Dio. Returns the decoded JSON body on success and
/// translates Dio transport/HTTP errors into the data layer's exception types
/// ([NetworkException], [ValidationException], [ServerException]).
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<DataMap> get(String path, {DataMap? queryParameters}) {
    return _send(() => _dio.get<dynamic>(path, queryParameters: queryParameters));
  }

  Future<DataMap> post(String path, {DataMap? data}) {
    return _send(() => _dio.post<dynamic>(path, data: data));
  }

  Future<DataMap> patch(String path, {DataMap? data}) {
    return _send(() => _dio.patch<dynamic>(path, data: data));
  }

  Future<DataMap> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is Map) {
        return body.cast<String, dynamic>();
      }
      // Non-object responses are wrapped so callers always get a DataMap.
      return <String, dynamic>{'data': body};
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Exception _mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const NetworkException('The request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkException('Invalid server certificate.');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return _mapResponseError(error);
    }
  }

  Exception _mapResponseError(DioException error) {
    final response = error.response;
    if (response == null) {
      return NetworkException(error.message ?? 'Network error.');
    }

    final statusCode = response.statusCode;
    var message = 'The request could not be completed.';
    Map<String, dynamic>? fieldErrors;

    final data = response.data;
    if (data is Map && data['error'] is Map) {
      final errorBody = (data['error'] as Map).cast<String, dynamic>();
      message = (errorBody['message'] as String?) ?? message;
      final details = errorBody['details'];
      if (details is Map) {
        fieldErrors = details.cast<String, dynamic>();
      }
    }

    if (statusCode == 422) {
      return ValidationException(
        message: message,
        errors: fieldErrors,
        statusCode: statusCode,
      );
    }
    return ServerException(message: message, statusCode: statusCode);
  }
}
