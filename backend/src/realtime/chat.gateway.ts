/**
 * Real-time chat & call signalling gateway.
 *
 * Registers all per-socket event handlers for an authenticated connection:
 *   - chat:join / chat:leave  — room membership scoped to an appointment,
 *   - chat:send               — persist + fan-out a message,
 *   - chat:typing             — ephemeral typing indicator,
 *   - chat:read               — read receipts,
 *   - call:start / call:end    — live video session lifecycle,
 *   - call:signal             — relay WebRTC SDP/ICE between peers.
 *
 * Each handler is wrapped so a thrown error is reported back through the ack
 * (when provided) and as a `chat:error` event, never crashing the connection.
 * Presence is broadcast to each joined room on connect/disconnect.
 */

import type { Server, Socket } from 'socket.io';
import { ApiError } from '../shared/apiError';
import { UserRole } from '../shared/enums';
import * as chatService from '../domain/services/chat.service';
import * as videoService from '../domain/services/video.service';
import type { Ack } from './types';

const OBJECT_ID = /^[0-9a-fA-F]{24}$/;

const roomName = (appointmentId: string): string => `chat_${appointmentId}`;

function reply<T>(ack: unknown, response: Parameters<Ack<T>>[0]): void {
  if (typeof ack === 'function') {
    (ack as Ack<T>)(response);
  }
}

function errorMessage(err: unknown): string {
  if (err instanceof ApiError) return err.message;
  if (err instanceof Error) return err.message;
  return 'Unexpected real-time error.';
}

/** Wrap an async handler so failures surface via ack + event instead of crashing. */
function safe(
  socket: Socket,
  handler: (payload: Record<string, unknown>, ack?: unknown) => Promise<void>,
) {
  return (payload: Record<string, unknown> = {}, ack?: unknown): void => {
    handler(payload, ack).catch((err) => {
      const message = errorMessage(err);
      socket.emit('chat:error', { message });
      reply(ack, { ok: false, error: message });
    });
  };
}

function requireAppointmentId(payload: Record<string, unknown>): string {
  const id = payload.appointmentId;
  if (typeof id !== 'string' || !OBJECT_ID.test(id)) {
    throw ApiError.badRequest('A valid appointmentId is required.');
  }
  return id;
}

export function registerChatHandlers(io: Server, socket: Socket): void {
  const user = socket.data.user as { id: string; role: UserRole };

  // --- join an appointment conversation -----------------------------------
  socket.on(
    'chat:join',
    safe(socket, async (payload, ack) => {
      const appointmentId = requireAppointmentId(payload);
      await chatService.assertParticipant(appointmentId, user.id, user.role);
      const room = roomName(appointmentId);
      await socket.join(room);

      const history = await chatService.getHistory(appointmentId, user.id, user.role, {
        limit: 50,
      });
      // Notify the counterparty that this user is now present.
      socket.to(room).emit('chat:presence', { userId: user.id, online: true });
      reply(ack, { ok: true, data: { appointmentId, history } });
    }),
  );

  // --- leave a conversation ------------------------------------------------
  socket.on(
    'chat:leave',
    safe(socket, async (payload, ack) => {
      const appointmentId = requireAppointmentId(payload);
      const room = roomName(appointmentId);
      await socket.leave(room);
      socket.to(room).emit('chat:presence', { userId: user.id, online: false });
      reply(ack, { ok: true });
    }),
  );

  // --- send a message ------------------------------------------------------
  socket.on(
    'chat:send',
    safe(socket, async (payload, ack) => {
      const appointmentId = requireAppointmentId(payload);
      const body = payload.body;
      if (typeof body !== 'string' || body.trim().length === 0) {
        throw ApiError.badRequest('Message body must be a non-empty string.');
      }
      const message = await chatService.saveMessage(appointmentId, user.id, user.role, body);
      // Deliver to everyone in the room, including the sender (for multi-device sync).
      io.to(roomName(appointmentId)).emit('chat:message', message);
      reply(ack, { ok: true, data: message });
    }),
  );

  // --- typing indicator (ephemeral) ---------------------------------------
  socket.on(
    'chat:typing',
    safe(socket, async (payload) => {
      const appointmentId = requireAppointmentId(payload);
      const isTyping = Boolean(payload.isTyping);
      socket.to(roomName(appointmentId)).emit('chat:typing', { userId: user.id, isTyping });
    }),
  );

  // --- read receipts -------------------------------------------------------
  socket.on(
    'chat:read',
    safe(socket, async (payload, ack) => {
      const appointmentId = requireAppointmentId(payload);
      const messageIds = Array.isArray(payload.messageIds)
        ? (payload.messageIds as unknown[]).filter((m): m is string => typeof m === 'string')
        : undefined;
      const updated = await chatService.markRead(appointmentId, user.id, user.role, messageIds);
      if (updated.length > 0) {
        io.to(roomName(appointmentId)).emit('chat:read', { by: user.id, messageIds: updated });
      }
      reply(ack, { ok: true, data: { messageIds: updated } });
    }),
  );

  // --- video call lifecycle ------------------------------------------------
  socket.on(
    'call:start',
    safe(socket, async (payload, ack) => {
      const appointmentId = requireAppointmentId(payload);
      const appointment = await videoService.markSessionStarted(appointmentId, user.id, user.role);
      socket.to(roomName(appointmentId)).emit('call:incoming', {
        by: user.id,
        channel: appointment.session.videoChannelName,
      });
      reply(ack, { ok: true, data: { channel: appointment.session.videoChannelName } });
    }),
  );

  socket.on(
    'call:end',
    safe(socket, async (payload, ack) => {
      const appointmentId = requireAppointmentId(payload);
      await videoService.markSessionEnded(appointmentId, user.id, user.role);
      io.to(roomName(appointmentId)).emit('call:ended', { by: user.id });
      reply(ack, { ok: true });
    }),
  );

  // --- WebRTC peer signalling relay ---------------------------------------
  socket.on(
    'call:signal',
    safe(socket, async (payload) => {
      const appointmentId = requireAppointmentId(payload);
      // Ensure the sender is a participant before relaying any signalling data.
      await chatService.assertParticipant(appointmentId, user.id, user.role);
      socket.to(roomName(appointmentId)).emit('call:signal', {
        from: user.id,
        signal: payload.signal ?? null,
      });
    }),
  );

  // --- presence cleanup on disconnect -------------------------------------
  socket.on('disconnecting', () => {
    for (const room of socket.rooms) {
      if (room.startsWith('chat_')) {
        socket.to(room).emit('chat:presence', { userId: user.id, online: false });
      }
    }
  });
}
