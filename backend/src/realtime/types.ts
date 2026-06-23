/**
 * Shared typings for the real-time (Socket.io) layer.
 */

import type { UserRole } from '../shared/enums';

/** Per-connection data attached after a successful handshake authentication. */
export interface SocketData {
  user: {
    id: string;
    role: UserRole;
  };
}

/** Standard acknowledgement envelope returned to socket emitters. */
export type AckResponse<T = unknown> =
  | { ok: true; data?: T }
  | { ok: false; error: string };

export type Ack<T = unknown> = (response: AckResponse<T>) => void;
