/**
 * Reusable primitive validators used by Mongoose `validate` options.
 *
 * These are deliberately framework-agnostic pure functions so they can also be
 * reused by the API-layer request validators (Zod/Joi) without duplication.
 */

// RFC 5322 inspired, pragmatic email pattern (avoids catastrophic backtracking).
const EMAIL_REGEX = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,63}$/;

// E.164 international phone format, e.g. +14155552671 (max 15 digits).
const E164_REGEX = /^\+[1-9]\d{6,14}$/;

// HH:mm 24-hour clock used by availability windows.
const HHMM_REGEX = /^([01]\d|2[0-3]):([0-5]\d)$/;

// URL-safe slug.
const SLUG_REGEX = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export const isEmail = (value: string): boolean => EMAIL_REGEX.test(value);

export const isE164Phone = (value: string): boolean => E164_REGEX.test(value);

export const isHHmm = (value: string): boolean => HHMM_REGEX.test(value);

export const isSlug = (value: string): boolean => SLUG_REGEX.test(value);

/** Converts an `HH:mm` string into minutes since midnight (0–1439). */
export const hhmmToMinutes = (value: string): number => {
  const [h, m] = value.split(':').map(Number);
  return h * 60 + m;
};

/**
 * Geo coordinate validator for GeoJSON `[longitude, latitude]` tuples.
 * MongoDB expects longitude first; we enforce valid ranges to avoid silent
 * indexing failures on the 2dsphere index.
 */
export const isLngLat = (coords: number[]): boolean => {
  if (!Array.isArray(coords) || coords.length !== 2) return false;
  const [lng, lat] = coords;
  return (
    Number.isFinite(lng) &&
    Number.isFinite(lat) &&
    lng >= -180 &&
    lng <= 180 &&
    lat >= -90 &&
    lat <= 90
  );
};
