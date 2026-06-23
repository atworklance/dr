/**
 * Password hashing helpers (bcrypt).
 *
 * Centralised so the cost factor is configured in exactly one place and the
 * plaintext password never lingers in service code beyond these functions.
 */

import bcrypt from 'bcryptjs';
import { config } from '../config';

export async function hashPassword(plaintext: string): Promise<string> {
  if (!plaintext || plaintext.length < 8) {
    throw new Error('Password must be at least 8 characters before hashing.');
  }
  return bcrypt.hash(plaintext, config.bcryptRounds);
}

export async function verifyPassword(plaintext: string, hash: string): Promise<boolean> {
  if (!plaintext || !hash) return false;
  return bcrypt.compare(plaintext, hash);
}
