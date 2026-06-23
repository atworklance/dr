import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// A future resolving to either a [Failure] or a value of type [T].
typedef ResultFuture<T> = Future<Either<Failure, T>>;

/// A future resolving to either a [Failure] or void.
typedef ResultVoid = ResultFuture<void>;

/// A decoded JSON object.
typedef DataMap = Map<String, dynamic>;
