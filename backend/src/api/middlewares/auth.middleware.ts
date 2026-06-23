/**
 * Authentication & authorisation middleware.
 *
 * `authenticate` verifies the Bearer JWT and attaches `req.user`.
 * `requireRole` is a guard factory that restricts a route to one or more roles.
 */

import type { NextFunction, Request, Response } from 'express';
import { ApiError } from '../../shared/apiError';
import { verifyAccessToken } from '../../shared/jwt';
import type { UserRole } from '../../shared/enums';

export function authenticate(req: Request, _res: Response, next: NextFunction): void {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      throw ApiError.unauthorized('Missing or malformed Authorization header.');
    }
    const token = header.slice('Bearer '.length).trim();
    if (!token) {
      throw ApiError.unauthorized('Empty bearer token.');
    }
    const claims = verifyAccessToken(token);
    req.user = { id: claims.sub, role: claims.role };
    next();
  } catch (err) {
    if (err instanceof ApiError) {
      next(err);
      return;
    }
    // jsonwebtoken throws on expiry/signature errors — normalise to 401.
    next(ApiError.unauthorized('Invalid or expired access token.'));
  }
}

export function requireRole(...roles: UserRole[]) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      next(ApiError.unauthorized());
      return;
    }
    if (!roles.includes(req.user.role)) {
      next(ApiError.forbidden(`This action requires one of roles: ${roles.join(', ')}.`));
      return;
    }
    next();
  };
}
