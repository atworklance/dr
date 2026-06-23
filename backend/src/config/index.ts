/**
 * Centralised, validated runtime configuration.
 *
 * Every environment-derived value is read and sanity-checked exactly once here,
 * so the rest of the codebase consumes a strongly-typed, guaranteed-present
 * config object instead of reaching into `process.env` ad-hoc.
 */

import type { SignOptions } from 'jsonwebtoken';

function required(name: string, fallback?: string): string {
  const value = process.env[name] ?? fallback;
  if (value === undefined || value === '') {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function intFromEnv(name: string, fallback: number): number {
  const raw = process.env[name];
  if (raw === undefined || raw === '') return fallback;
  const parsed = Number.parseInt(raw, 10);
  if (!Number.isFinite(parsed)) {
    throw new Error(`Environment variable ${name} must be an integer.`);
  }
  return parsed;
}

function floatFromEnv(name: string, fallback: number): number {
  const raw = process.env[name];
  if (raw === undefined || raw === '') return fallback;
  const parsed = Number.parseFloat(raw);
  if (!Number.isFinite(parsed)) {
    throw new Error(`Environment variable ${name} must be a number.`);
  }
  return parsed;
}

const isProd = process.env.NODE_ENV === 'production';

export const config = {
  env: process.env.NODE_ENV ?? 'development',
  isProd,
  port: intFromEnv('PORT', 4000),
  mongoUri: required('MONGODB_URI', isProd ? undefined : 'mongodb://127.0.0.1:27017/drplus'),
  jwt: {
    // In production the secret MUST be supplied; in dev we fall back to a
    // clearly non-secret default so the app still boots for local testing.
    secret: required('JWT_SECRET', isProd ? undefined : 'dev-insecure-jwt-secret-change-me'),
    expiresIn: (process.env.JWT_EXPIRES_IN ?? '7d') as SignOptions['expiresIn'],
    issuer: process.env.JWT_ISSUER ?? 'drplus.api',
  },
  bcryptRounds: intFromEnv('BCRYPT_ROUNDS', 12),
  /** Default platform commission as a fraction (0–1) when a provider has no override. */
  defaultCommissionRate: floatFromEnv('DEFAULT_COMMISSION_RATE', 0.15),
  /** Minimum provider withdrawal amount, in integer minor currency units (cents). */
  minWithdrawalMinorUnits: intFromEnv('MIN_WITHDRAWAL_MINOR_UNITS', 1000),
  /** Agora real-time video configuration. */
  agora: {
    appId: process.env.AGORA_APP_ID ?? '',
    appCertificate: process.env.AGORA_APP_CERTIFICATE ?? '',
    /** Lifetime of an issued RTC token / privilege, in seconds (default 1h). */
    tokenTtlSeconds: intFromEnv('AGORA_TOKEN_TTL_SECONDS', 3600),
  },
} as const;

/** True only when Agora credentials are fully configured. */
export const isAgoraConfigured = (): boolean =>
  config.agora.appId.length > 0 && config.agora.appCertificate.length > 0;

if (config.defaultCommissionRate < 0 || config.defaultCommissionRate > 1) {
  throw new Error('DEFAULT_COMMISSION_RATE must be a fraction between 0 and 1.');
}
