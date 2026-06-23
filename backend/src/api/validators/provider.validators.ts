/**
 * Zod request validators for the public specialist (provider) search endpoint.
 */

import { z } from 'zod';
import { CONSULTATION_MODES } from '../../shared/enums';

export const searchProvidersSchema = z
  .object({
    /** Free-text query across name, headline, and specialties. */
    q: z.string().trim().min(1).max(120).optional(),
    /** Exact specialty slug filter. */
    specialty: z.string().trim().toLowerCase().max(80).optional(),
    /** Consultation mode filter. */
    mode: z.enum(CONSULTATION_MODES as unknown as [string, ...string[]]).optional(),
    /** Minimum average rating (0–5). */
    minRating: z.coerce.number().min(0).max(5).optional(),
    /** Proximity centre (both required together). */
    lat: z.coerce.number().min(-90).max(90).optional(),
    lng: z.coerce.number().min(-180).max(180).optional(),
    /** Search radius in km (used only with lat/lng). */
    radiusKm: z.coerce.number().min(0.1).max(500).optional(),
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
  })
  .strict()
  .superRefine((data, ctx) => {
    const hasLat = data.lat !== undefined;
    const hasLng = data.lng !== undefined;
    if (hasLat !== hasLng) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: [hasLat ? 'lng' : 'lat'],
        message: 'Both lat and lng are required for a proximity search.',
      });
    }
  });

export type SearchProvidersQuery = z.infer<typeof searchProvidersSchema>;
