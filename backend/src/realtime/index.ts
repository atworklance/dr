/**
 * Socket.io server bootstrap.
 *
 * Attaches a Socket.io server to the shared HTTP server, installs the handshake
 * auth middleware, and wires the chat/call gateway onto every connection.
 * `getIO()` exposes the singleton so non-socket code (e.g. background jobs) can
 * emit into rooms when needed.
 */

import type { Server as HttpServer } from 'http';
import { Server } from 'socket.io';
import { authenticateSocket } from './socketAuth';
import { registerChatHandlers } from './chat.gateway';

let io: Server | null = null;

export function initSocketServer(httpServer: HttpServer): Server {
  if (io) return io;

  io = new Server(httpServer, {
    path: '/socket.io',
    cors: {
      // Tighten to the mobile app / web origins in production via env config.
      origin: process.env.SOCKET_CORS_ORIGIN ?? '*',
      methods: ['GET', 'POST'],
    },
    pingTimeout: 20_000,
    pingInterval: 25_000,
  });

  io.use(authenticateSocket);

  io.on('connection', (socket) => {
    registerChatHandlers(io as Server, socket);
  });

  return io;
}

export function getIO(): Server {
  if (!io) {
    throw new Error('Socket.io server has not been initialised. Call initSocketServer() first.');
  }
  return io;
}
