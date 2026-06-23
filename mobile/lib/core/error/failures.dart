import 'package:equatable/equatable.dart';

/// Domain-level error type. Every repository method returns `Either<Failure, T>`
/// so the presentation layer handles errors exhaustively and type-safely.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// A backend/server-side error (4xx/5xx other than validation).
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

/// A 422 validation error, exposing the per-field messages for form binding.
class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    this.fieldErrors,
    super.statusCode = 422,
  });

  final Map<String, dynamic>? fieldErrors;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// Loss of connectivity or a request timeout.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection available.']);
}

/// Local persistence failure.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not read locally stored data.']);
}

/// No authenticated session present where one was required.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'You are not authenticated.']);
}
