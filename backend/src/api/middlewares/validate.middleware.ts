/**
 * Request validation middleware factory.
 *
 * Parses a chosen request part (`body` | `params` | `query`) against a Zod
 * schema. On success the parsed/coerced value REPLACES the raw input so
 * downstream handlers receive typed, sanitised data. On failure it forwards a
 * 422 ApiError carrying a flattened field-error map.
 */

import type { NextFunction, Request, Response } from 'express';
import { ZodError, type ZodTypeAny } from 'zod';
import { ApiError } from '../../shared/apiError';

type RequestPart = 'body' | 'params' | 'query';

export function validate(schema: ZodTypeAny, part: RequestPart = 'body') {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      const parsed = schema.parse(req[part]);
      // Express 4 allows reassigning these; cast through unknown to satisfy TS.
      (req as unknown as Record<RequestPart, unknown>)[part] = parsed;
      next();
    } catch (err) {
      if (err instanceof ZodError) {
        next(ApiError.unprocessable('Request validation failed', err.flatten()));
        return;
      }
      next(err);
    }
  };
}
