/**
 * Process entry point: connect to MongoDB, start the HTTP server, and wire
 * graceful shutdown on termination signals.
 */

import { createApp } from './app';
import { config } from './config';
import { connectDatabase, disconnectDatabase } from './data/db';

async function bootstrap(): Promise<void> {
  await connectDatabase(config.mongoUri);

  const app = createApp();
  const server = app.listen(config.port, () => {
    // eslint-disable-next-line no-console
    console.info(`[server] Dr.Plus API listening on port ${config.port} (${config.env}).`);
  });

  const shutdown = async (signal: string): Promise<void> => {
    // eslint-disable-next-line no-console
    console.info(`[server] ${signal} received — shutting down gracefully.`);
    server.close(async () => {
      await disconnectDatabase();
      process.exit(0);
    });
    // Force-exit if connections do not drain in time.
    setTimeout(() => process.exit(1), 10_000).unref();
  };

  process.on('SIGINT', () => void shutdown('SIGINT'));
  process.on('SIGTERM', () => void shutdown('SIGTERM'));
}

bootstrap().catch((err) => {
  // eslint-disable-next-line no-console
  console.error('[server] Fatal bootstrap error:', err);
  process.exit(1);
});
