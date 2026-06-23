import 'package:dartz/dartz.dart';

import '../error/exceptions.dart';
import '../error/failures.dart';
import '../network/network_info.dart';

/// Translates a thrown data-layer [Exception] into a domain [Failure].
Failure mapExceptionToFailure(Object error) {
  if (error is ValidationException) {
    return ValidationFailure(
      error.message,
      fieldErrors: error.errors,
      statusCode: error.statusCode,
    );
  }
  if (error is ServerException) {
    return ServerFailure(error.message, statusCode: error.statusCode);
  }
  if (error is NetworkException) {
    return NetworkFailure(error.message);
  }
  if (error is CacheException) {
    return CacheFailure(error.message);
  }
  return const ServerFailure('An unexpected error occurred.');
}

/// Wraps a value-returning remote call with the standard connectivity check +
/// exception->Failure translation. Returns `Left(NetworkFailure)` when offline.
Future<Either<Failure, T>> guardRemote<T>(
  NetworkInfo networkInfo,
  Future<T> Function() body,
) async {
  if (!await networkInfo.isConnected) {
    return const Left(NetworkFailure());
  }
  try {
    return Right(await body());
  } catch (error) {
    return Left(mapExceptionToFailure(error));
  }
}

/// Wraps a void-returning remote call (same guards, no payload).
Future<Either<Failure, void>> guardRemoteVoid(
  NetworkInfo networkInfo,
  Future<void> Function() body,
) async {
  if (!await networkInfo.isConnected) {
    return const Left(NetworkFailure());
  }
  try {
    await body();
    return const Right(null);
  } catch (error) {
    return Left(mapExceptionToFailure(error));
  }
}

/// Wraps a purely local call (no connectivity requirement) with exception
/// translation.
Future<Either<Failure, T>> guardLocal<T>(Future<T> Function() body) async {
  try {
    return Right(await body());
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (_) {
    return const Left(CacheFailure());
  }
}
