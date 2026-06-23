/**
 * Ambient augmentation that attaches the authenticated principal to Express's
 * Request, populated by the auth middleware after a valid JWT is verified.
 */

import type { UserRole } from '../../shared/enums';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: {
        id: string;
        role: UserRole;
      };
    }
  }
}

export {};
