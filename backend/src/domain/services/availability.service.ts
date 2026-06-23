/**
 * Provider availability domain logic.
 *
 * Pure, framework-free functions that decide whether a requested time window is
 * bookable against a provider's availability matrix. Used both by the booking
 * pipeline (to reject out-of-hours requests before persistence) and reusable by
 * a future "available slots" discovery endpoint.
 *
 * Time interpretation: availability windows are expressed in `HH:mm` and are
 * evaluated in UTC. Requested slots are therefore compared by their UTC
 * weekday and minute-of-day. (Per-provider timezone handling can layer on top
 * later without changing these signatures.)
 */

import type { ConsultationMode } from '../../shared/enums';
import type { IProvider } from '../../data/models';

export interface SlotDecision {
  ok: boolean;
  reason?: string;
}

const minutesOfDayUTC = (d: Date): number => d.getUTCHours() * 60 + d.getUTCMinutes();

const toMinutes = (hhmm: string): number => {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
};

const sameUTCDate = (a: Date, b: Date): boolean =>
  a.getUTCFullYear() === b.getUTCFullYear() &&
  a.getUTCMonth() === b.getUTCMonth() &&
  a.getUTCDate() === b.getUTCDate();

/** True when [aStart,aEnd) and [bStart,bEnd) overlap. */
const overlaps = (aStart: number, aEnd: number, bStart: number, bEnd: number): boolean =>
  aStart < bEnd && bStart < aEnd;

/** True when [innerStart,innerEnd) is fully contained in [outerStart,outerEnd]. */
const contained = (
  innerStart: number,
  innerEnd: number,
  outerStart: number,
  outerEnd: number,
): boolean => innerStart >= outerStart && innerEnd <= outerEnd;

/**
 * Decide whether `start`–`end` is a bookable slot for `provider` in `mode`.
 * Does not consider existing bookings (that collision is enforced atomically by
 * the appointment unique index); this purely validates schedule eligibility.
 */
export function isSlotBookable(
  provider: Pick<
    IProvider,
    | 'holidayMode'
    | 'isAcceptingNewClients'
    | 'consultationModes'
    | 'pricing'
    | 'weeklyAvailability'
    | 'availabilityExceptions'
  >,
  start: Date,
  end: Date,
  mode: ConsultationMode,
): SlotDecision {
  if (provider.holidayMode) {
    return { ok: false, reason: 'Provider is currently in Holiday Mode.' };
  }
  if (!provider.isAcceptingNewClients) {
    return { ok: false, reason: 'Provider is not accepting new clients.' };
  }
  if (!provider.consultationModes.includes(mode)) {
    return { ok: false, reason: `Provider does not offer ${mode} consultations.` };
  }
  if (end.getTime() <= start.getTime()) {
    return { ok: false, reason: 'end must be after start.' };
  }
  if (!sameUTCDate(start, end)) {
    return { ok: false, reason: 'A slot cannot span across calendar days.' };
  }

  const durationMinutes = Math.round((end.getTime() - start.getTime()) / 60000);
  if (durationMinutes !== provider.pricing.sessionDurationMinutes) {
    return {
      ok: false,
      reason: `Slot duration must equal the provider's session length of ${provider.pricing.sessionDurationMinutes} minutes.`,
    };
  }

  const slotStart = minutesOfDayUTC(start);
  const slotEnd = slotStart + durationMinutes;

  // 1) Date-specific exceptions take precedence over recurring availability.
  const exception = provider.availabilityExceptions.find((ex) => sameUTCDate(ex.date, start));
  if (exception) {
    if (exception.isFullDayOff) {
      return { ok: false, reason: 'Provider is unavailable on this date.' };
    }
    if (exception.windows.length > 0) {
      const fits = exception.windows.some((w) =>
        contained(slotStart, slotEnd, toMinutes(w.startTime), toMinutes(w.endTime)),
      );
      return fits
        ? { ok: true }
        : { ok: false, reason: 'Requested time is outside the provider\'s exception windows for this date.' };
    }
    // Exception present but neither full-day-off nor windowed → fall through.
  }

  // 2) Recurring weekly availability for this UTC weekday.
  const weekday = start.getUTCDay();
  const windows = provider.weeklyAvailability.filter((w) => w.weekday === weekday);
  if (windows.length === 0) {
    return { ok: false, reason: 'Provider has no availability on this weekday.' };
  }

  const hostWindow = windows.find((w) =>
    contained(slotStart, slotEnd, toMinutes(w.startTime), toMinutes(w.endTime)),
  );
  if (!hostWindow) {
    return { ok: false, reason: 'Requested time is outside the provider\'s working hours.' };
  }

  // 3) The slot must not collide with any break in its host window.
  const hitsBreak = hostWindow.breaks.some((br) =>
    overlaps(slotStart, slotEnd, toMinutes(br.startTime), toMinutes(br.endTime)),
  );
  if (hitsBreak) {
    return { ok: false, reason: 'Requested time overlaps a scheduled break.' };
  }

  return { ok: true };
}
