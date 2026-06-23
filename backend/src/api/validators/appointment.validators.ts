/**
 * Zod request validators for the appointment booking pipeline.
 */

import { z } from 'zod';
import { CONSULTATION_MODES } from '../../shared/enums';
import { isoDateTime, objectId } from './common.validators';

export const createAppointmentSchema = z
  .object({
    providerId: objectId,
    consultationMode: z.enum(CONSULTATION_MODES as unknown as [string, ...string[]]),
    start: isoDateTime,
    end: isoDateTime,
    notes: z.string().max(5000).optional(),
  })
  .strict()
  .superRefine((data, ctx) => {
    if (data.end.getTime() <= data.start.getTime()) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['end'],
        message: 'end must be strictly after start.',
      });
    }
    if (data.start.getTime() <= Date.now()) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['start'],
        message: 'start must be in the future.',
      });
    }
  });
export type CreateAppointmentInput = z.infer<typeof createAppointmentSchema>;

export const cancelAppointmentSchema = z
  .object({
    reason: z.string().trim().max(500).optional(),
  })
  .strict();
export type CancelAppointmentInput = z.infer<typeof cancelAppointmentSchema>;

export const listAppointmentsQuerySchema = z
  .object({
    status: z.string().trim().optional(),
    from: isoDateTime.optional(),
    to: isoDateTime.optional(),
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
  })
  .strict();
export type ListAppointmentsQuery = z.infer<typeof listAppointmentsQuerySchema>;
