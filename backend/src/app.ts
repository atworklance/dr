/**
 * Express application factory.
 *
 * Wires global middleware, the versioned API router, and the terminal
 * not-found + error handlers. Kept free of any `listen()` call so it can be
 * imported directly by integration tests.
 */

import express, { type Application } from 'express';
import helmet from 'helmet';
import apiV1 from './api/routes';
import { errorHandler, notFoundHandler } from './api/middlewares/error.middleware';

export function createApp(): Application {
  const app = express();

  app.disable('x-powered-by');
  app.use(helmet());
  app.use(express.json({ limit: '256kb' }));
  app.use(express.urlencoded({ extended: true }));

  app.use('/api/v1', apiV1);

  // Terminal handlers (order matters: 404 first, then the error serialiser).
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
