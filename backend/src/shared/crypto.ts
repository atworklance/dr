/**
 * Field-level encryption helper for sensitive payloads stored at rest
 * (e.g. encrypted client appointment notes).
 *
 * Uses AES-256-GCM (authenticated encryption) with a per-record random IV.
 * The 256-bit key is derived once, at module load, from the hex master secret
 * supplied via `FIELD_ENCRYPTION_KEY`. Decryption verifies the GCM auth tag,
 * so any tampering with the ciphertext throws instead of returning corrupt data.
 */

import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12; // 96-bit nonce — recommended size for GCM.
const KEY_LENGTH = 32; // 256-bit key.

/** Serialised encrypted envelope persisted in MongoDB. */
export interface EncryptedPayload {
  /** Base64 initialisation vector. */
  iv: string;
  /** Base64 ciphertext. */
  content: string;
  /** Base64 GCM authentication tag. */
  authTag: string;
}

function resolveKey(): Buffer {
  const raw = process.env.FIELD_ENCRYPTION_KEY;
  if (!raw) {
    throw new Error(
      'FIELD_ENCRYPTION_KEY is not set. A 64-char hex (32-byte) key is required for field encryption.',
    );
  }
  const key = Buffer.from(raw, 'hex');
  if (key.length !== KEY_LENGTH) {
    throw new Error(
      `FIELD_ENCRYPTION_KEY must decode to ${KEY_LENGTH} bytes (got ${key.length}). Generate with: openssl rand -hex 32`,
    );
  }
  return key;
}

/** Encrypts a UTF-8 string into a verifiable AES-256-GCM envelope. */
export function encryptField(plaintext: string): EncryptedPayload {
  if (typeof plaintext !== 'string') {
    throw new TypeError('encryptField expects a string plaintext.');
  }
  const key = resolveKey();
  const iv = randomBytes(IV_LENGTH);
  const cipher = createCipheriv(ALGORITHM, key, iv);
  const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return {
    iv: iv.toString('base64'),
    content: encrypted.toString('base64'),
    authTag: authTag.toString('base64'),
  };
}

/** Decrypts an AES-256-GCM envelope back to its UTF-8 plaintext. */
export function decryptField(payload: EncryptedPayload): string {
  if (!payload || !payload.iv || !payload.content || !payload.authTag) {
    throw new Error('decryptField received a malformed EncryptedPayload.');
  }
  const key = resolveKey();
  const decipher = createDecipheriv(ALGORITHM, key, Buffer.from(payload.iv, 'base64'));
  decipher.setAuthTag(Buffer.from(payload.authTag, 'base64'));
  const decrypted = Buffer.concat([
    decipher.update(Buffer.from(payload.content, 'base64')),
    decipher.final(),
  ]);
  return decrypted.toString('utf8');
}
