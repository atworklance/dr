import 'package:equatable/equatable.dart';

import '../utils/typedefs.dart';

/// Base contract for a use case that requires input [Params].
abstract class UseCase<Type, Params> {
  const UseCase();

  ResultFuture<Type> call(Params params);
}

/// Base contract for a use case that requires no input.
abstract class UseCaseWithoutParams<Type> {
  const UseCaseWithoutParams();

  ResultFuture<Type> call();
}

/// Sentinel for use cases that take no parameters but must satisfy [UseCase].
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
