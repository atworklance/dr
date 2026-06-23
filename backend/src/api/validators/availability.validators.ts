/**
 * Zod request validators for provider availability scheduling.
 *
 * Mirrors the Provider model's availability matrix: recurring weekly windows
 * (with intra-window breaks), date-specific exceptions, and the Holiday Mode
 * switch. All time-range relationships (end > start, breaks inside parent) are
 * enforced here so invalid schedules are rejected before touching the DB.
 */

import { z } from 'zod';
import { hhmm, isoDateTime } from './common.validators';

const toMinutes = (v: string): number => {
  const [h, m] = v.split(':').map(Number);
  return h * 60 + m;
};

const timeRange = z
  .object({ startTime: hhmm, endTime: hhmm })
  .refine((r) => toMinutes(r.endTime) > toMinutes(r.startTime), {
    message: 'endTime must be strictly after startTime.',
    path: ['endTime'],
  });

const availabilityWindow = z
  .object({
    weekday: z.number().int().min(0).max(6),
    startTime: hhmm,
    endTime: hhmm,
    breaks: z.array(timeRange).max(12).default([]),
  })
  .superRefine((win, ctx) => {
    const winStart = toMinutes(win.startTime);
    const winEnd = toMinutes(win.endTime);
    if (winEnd <= winStart) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['endTime'],
        message: 'endTime must be strictly after startTime.',
      });
      return;
    }
    win.breaks.forEach((br, i) => {
      const bs = toMinutes(br.startTime);
      const be = toMinutes(br.endTime);
      if (bs < winStart || be > winEnd) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['breaks', i],
          message: 'Break must fall within its parent availability window.',
        });
      }
    });
  });

export const updateWeeklyAvailabilitySchema = z
  .object({
    weeklyAvailability: z.array(availabilityWindow).max(50),
  })
  .strict();
export type UpdateWeeklyAvailabilityInput = z.infer<typeof updateWeeklyAvailabilitySchema>;

export const upsertAvailabilityExceptionSchema = z
  .object({
    date: isoDateTime,
    isFullDayOff: z.boolean().default(true),
    windows: z.array(timeRange).max(12).default([]),
    reason: z.string().trim().max(280).optional(),
  })
  .strict()
  .superRefine((data, ctx) => {
    if (!data.isFullDayOff && data.windows.length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['windows'],
        message: 'Provide at least one window when the day is not a full day off.',
      });
    }
  });
export type UpsertAvailabilityExceptionInput = z.infer<typeof upsertAvailabilityExceptionSchema>;

export const setHolidayModeSchema = z
  .object({ holidayMode: z.boolean() })
  .strict();
export type SetHolidayModeInput = z.infer<typeof setHolidayModeSchema>;
