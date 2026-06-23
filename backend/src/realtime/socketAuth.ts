/**
 * Socket.io handshake authentication middleware.
 *
 * Accepts the JWT from `handshake.auth.token` (preferred) or a Bearer
 * Authorization header, verifies it, and attaches the principal to
 * `socket.data.user`. A failed verification rejects the connection.
 */

import type { Socket } from 'socket.io';
import type { ExtendedError } from 'socket.io/dist/namespace';
import { verifyAccessToken } from '../shared/jwt';

function extractToken(socket: Socket): string | null {
  const authToken = socket.handshake.auth?.token;
  if (typeof authToken === 'string' && authToken.length > 0) {
    return authToken.replace(/^Bearer\s+/i, '').trim();
  }
  const header = socket.handshake.headers.authorization;
  if (typeof header === 'string' && header.startsWith('Bearer ')) {
    return header.slice('Bearer '.length).trim();
  }
  return null;
}

export function authenticateSocket(socket: Socket, next: (err?: ExtendedError) => void): void {
  try {
    const token = extractToken(socket);
    if (!token) {
      next(new Error('Unauthorized: missing authentication token.'));
      return;
    }
    const claims = verifyAccessToken(token);
    socket.data.user = { id: claims.sub, role: claims.role };
    next();
  } catch {
    next(new Error('Unauthorized: invalid or expired token.'));
  }
}
