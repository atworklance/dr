/**
 * MongoDB connection bootstrap.
 *
 * Centralises Mongoose configuration so the rest of the app never touches the
 * driver directly. Enables strict query filtering, sane pool sizing, and
 * registers connection lifecycle handlers for resilient operation. Calling
 * `connectDatabase()` also ensures all declared indexes are built in non-prod
 * environments (in production, prefer migrations / `syncIndexes` jobs).
 */

import mongoose from 'mongoose';
import './models'; // side-effect: register every model/schema.

mongoose.set('strictQuery', true);

let connectionPromise: Promise<typeof mongoose> | null = null;

export async function connectDatabase(uri = process.env.MONGODB_URI): Promise<typeof mongoose> {
  if (!uri) {
    throw new Error('MONGODB_URI is not set; cannot establish a database connection.');
  }
  if (connectionPromise) return connectionPromise;

  connectionPromise = mongoose
    .connect(uri, {
      maxPoolSize: 25,
      minPoolSize: 2,
      serverSelectionTimeoutMS: 10_000,
      socketTimeoutMS: 45_000,
      autoIndex: process.env.NODE_ENV !== 'production',
    })
    .then((conn) => {
      // eslint-disable-next-line no-console
      console.info(`[db] connected to MongoDB (${conn.connection.name}).`);
      return conn;
    })
    .catch((err) => {
      connectionPromise = null;
      throw err;
    });

  mongoose.connection.on('error', (err) => {
    // eslint-disable-next-line no-console
    console.error('[db] connection error:', err);
  });
  mongoose.connection.on('disconnected', () => {
    // eslint-disable-next-line no-console
    console.warn('[db] disconnected from MongoDB.');
  });

  return connectionPromise;
}

export async function disconnectDatabase(): Promise<void> {
  await mongoose.disconnect();
  connectionPromise = null;
}
