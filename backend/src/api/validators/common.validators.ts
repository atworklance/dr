/**
 * Reusable Zod primitives shared across request validators.
 */

import { z } from 'zod';
import { SUPPORTED_CURRENCIES } from '../../shared/enums';

/** A 24-char hex MongoDB ObjectId. */
export const objectId = z
  .string()
  .regex(/^[0-9a-fA-F]{24}$/, 'Must be a valid 24-character ObjectId.');

/** `HH:mm` 24-hour clock time. */
export const hhmm = z
  .string()
  .regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Time must be in HH:mm (24h) format.');

/** ISO-8601 datetime string coerced to a Date. */
export const isoDateTime = z
  .string()
  .datetime({ offset: true, message: 'Must be an ISO-8601 datetime string.' })
  .transform((v) => new Date(v));

/** GeoJSON [longitude, latitude] tuple. */
export const lngLat = z
  .tuple([
    z.number().min(-180).max(180),
    z.number().min(-90).max(90),
  ])
  .describe('[longitude, latitude]');

export const geoPoint = z.object({
  type: z.literal('Point').default('Point'),
  coordinates: lngLat,
});

export const currency = z.enum(
  SUPPORTED_CURRENCIES as unknown as [string, ...string[]],
);

export const idParam = z.object({ id: objectId });
