/**
 * Operational HTTP error type.
 *
 * Controllers and services throw `ApiError` to signal an expected, client-facing
 * failure with a precise status code. The central error middleware recognises
 * this type and serialises it deterministically, distinguishing it from
 * unexpected (programmer) errors which are masked behind a generic 500.
 */

export class ApiError extends Error {
  public readonly statusCode: number;
  public readonly details?: unknown;
  public readonly isOperational = true;

  constructor(statusCode: number, message: string, details?: unknown) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.details = details;
    Error.captureStackTrace?.(this, ApiError);
  }

  static badRequest(message = 'Bad request', details?: unknown): ApiError {
    return new ApiError(400, message, details);
  }
  static unauthorized(message = 'Authentication required', details?: unknown): ApiError {
    return new ApiError(401, message, details);
  }
  static forbidden(message = 'You do not have permission to perform this action', details?: unknown): ApiError {
    return new ApiError(403, message, details);
  }
  static notFound(message = 'Resource not found', details?: unknown): ApiError {
    return new ApiError(404, message, details);
  }
  static conflict(message = 'Resource conflict', details?: unknown): ApiError {
    return new ApiError(409, message, details);
  }
  static unprocessable(message = 'Validation failed', details?: unknown): ApiError {
    return new ApiError(422, message, details);
  }
}
