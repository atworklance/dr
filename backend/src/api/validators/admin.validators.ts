/**
 * Zod validators for the admin Platform Control Hub endpoints.
 */

import { z } from 'zod';
import { VERIFICATION_STATUSES } from '../../shared/enums';

export const listProvidersQuerySchema = z
  .object({
    status: z.enum(VERIFICATION_STATUSES as unknown as [string, ...string[]]).optional(),
    q: z.string().trim().min(1).max(120).optional(),
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
  })
  .strict();
export type ListProvidersQueryInput = z.infer<typeof listProvidersQuerySchema>;

export const setVerificationSchema = z
  .object({
    status: z.enum(['approved', 'rejected']),
    note: z.string().trim().max(1000).optional(),
  })
  .strict();
export type SetVerificationInput = z.infer<typeof setVerificationSchema>;

export const setProviderCommissionSchema = z
  .object({
    // `null` clears the override so the provider falls back to the platform rate.
    rate: z.number().min(0).max(1).nullable(),
  })
  .strict();
export type SetProviderCommissionInput = z.infer<typeof setProviderCommissionSchema>;

export const setPlatformCommissionSchema = z
  .object({
    rate: z.number().min(0).max(1),
  })
  .strict();
export type SetPlatformCommissionInput = z.infer<typeof setPlatformCommissionSchema>;
