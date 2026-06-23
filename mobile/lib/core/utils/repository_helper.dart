import 'package:dartz/dartz.dart';

import '../error/exceptions.dart';
import '../error/failures.dart';
import '../network/network_info.dart';

/// Wraps a remote call with the standard connectivity check + exception->Failure
/// translation, so every repository method stays a one-liner and behaves
/// consistently. Returns `Left(NetworkFailure)` when offline.
Future<Either<Failure, T>> guardRemote<T>(
  NetworkInfo networkInfo,
  Future<T> Function() body,
) async {
  if (!await networkInfo.isConnected) {
    return const Left(NetworkFailure());
  }
  try {
    final result = await body();
    return Right(result);
  } on ValidationException catch (e) {
    return Left(
      ValidationFailure(e.message, fieldErrors: e.errors, statusCode: e.statusCode),
    );
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, statusCode: e.statusCode));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (_) {
    return const Left(ServerFailure('An unexpected error occurred.'));
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
