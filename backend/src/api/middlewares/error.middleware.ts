/**
 * Centralised error handling.
 *
 * `notFoundHandler` converts unmatched routes into a 404 ApiError.
 * `errorHandler` is the single terminal middleware that serialises every error
 * shape — ApiError, Zod, Mongoose validation/cast, duplicate-key — into a
 * consistent JSON envelope, masking unexpected errors behind a generic 500.
 */

import type { NextFunction, Request, Response } from 'express';
import { Error as MongooseError } from 'mongoose';
import { ZodError } from 'zod';
import { ApiError } from '../../shared/apiError';
import { config } from '../../config';

interface MongoServerError extends Error {
  code?: number;
  keyValue?: Record<string, unknown>;
}

export function notFoundHandler(req: Request, _res: Response, next: NextFunction): void {
  next(ApiError.notFound(`Route not found: ${req.method} ${req.originalUrl}`));
}

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  // `next` is required for Express to recognise this as an error handler.
  _next: NextFunction,
): void {
  let statusCode = 500;
  let message = 'Internal server error';
  let details: unknown;

  if (err instanceof ApiError) {
    statusCode = err.statusCode;
    message = err.message;
    details = err.details;
  } else if (err instanceof ZodError) {
    statusCode = 422;
    message = 'Request validation failed';
    details = err.flatten();
  } else if (err instanceof MongooseError.ValidationError) {
    statusCode = 422;
    message = 'Document validation failed';
    details = Object.fromEntries(
      Object.entries(err.errors).map(([field, e]) => [field, e.message]),
    );
  } else if (err instanceof MongooseError.CastError) {
    statusCode = 400;
    message = `Invalid value for "${err.path}".`;
  } else if ((err as MongoServerError)?.code === 11000) {
    statusCode = 409;
    message = 'Duplicate key: a record with these unique fields already exists.';
    details = (err as MongoServerError).keyValue;
  }

  if (statusCode >= 500) {
    // eslint-disable-next-line no-console
    console.error('[error]', err);
  }

  res.status(statusCode).json({
    success: false,
    error: {
      message,
      ...(details !== undefined ? { details } : {}),
      ...(config.isProd ? {} : { stack: err instanceof Error ? err.stack : undefined }),
    },
  });
}
