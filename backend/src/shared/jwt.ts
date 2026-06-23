/**
 * JSON Web Token issue/verify helpers for stateless authentication.
 */

import jwt, { type SignOptions } from 'jsonwebtoken';
import { config } from '../config';
import type { UserRole } from './enums';

export interface AccessTokenClaims {
  /** Subject — the authenticated user's id. */
  sub: string;
  role: UserRole;
}

export function signAccessToken(claims: AccessTokenClaims): string {
  const options: SignOptions = {
    expiresIn: config.jwt.expiresIn,
    issuer: config.jwt.issuer,
  };
  return jwt.sign(claims, config.jwt.secret, options);
}

export function verifyAccessToken(token: string): AccessTokenClaims {
  const decoded = jwt.verify(token, config.jwt.secret, { issuer: config.jwt.issuer });
  if (typeof decoded === 'string' || !decoded.sub || !(decoded as AccessTokenClaims).role) {
    throw new Error('Malformed access token payload.');
  }
  return { sub: String(decoded.sub), role: (decoded as AccessTokenClaims).role };
}
