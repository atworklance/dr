/// Low-level exceptions thrown by the data layer (data sources). Repositories
/// catch these and translate them into [Failure]s for the domain layer.

/// Thrown when the backend returns a non-2xx response that is not a validation
/// error (4xx/5xx).
class ServerException implements Exception {
  const ServerException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown when the backend rejects a request with a 422 validation error,
/// carrying the per-field error map produced by the API's Zod layer.
class ValidationException implements Exception {
  const ValidationException({
    required this.message,
    this.errors,
    this.statusCode = 422,
  });

  final String message;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  @override
  String toString() => 'ValidationException: $message';
}

/// Thrown when the device has no usable connectivity or the request times out.
class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection available.']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when reading/writing local persistence (secure storage) fails.
class CacheException implements Exception {
  const CacheException([this.message = 'Local cache operation failed.']);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}
