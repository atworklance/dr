/**
 * Provider availability controllers.
 *
 * All handlers operate on the authenticated provider's own profile (resolved
 * from `req.user.id`), so a provider can never mutate another's schedule.
 */

import type { NextFunction, Request, Response } from 'express';
import { Provider } from '../../data/models';
import { ApiError } from '../../shared/apiError';
import type {
  SetHolidayModeInput,
  UpdateWeeklyAvailabilityInput,
  UpsertAvailabilityExceptionInput,
} from '../validators/availability.validators';

async function loadOwnProfile(userId: string) {
  const provider = await Provider.findOne({ user: userId });
  if (!provider) {
    throw ApiError.notFound('Provider profile not found for the current user.');
  }
  return provider;
}

export async function getMyAvailability(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const provider = await loadOwnProfile(req.user!.id);
    res.status(200).json({
      success: true,
      data: {
        weeklyAvailability: provider.weeklyAvailability,
        availabilityExceptions: provider.availabilityExceptions,
        holidayMode: provider.holidayMode,
        bookingLeadTimeMinutes: provider.bookingLeadTimeMinutes,
        isAcceptingNewClients: provider.isAcceptingNewClients,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function updateWeeklyAvailability(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const provider = await loadOwnProfile(req.user!.id);
    const { weeklyAvailability } = req.body as UpdateWeeklyAvailabilityInput;
    provider.weeklyAvailability = weeklyAvailability as typeof provider.weeklyAvailability;
    await provider.save(); // triggers subdocument schema + pre-validate hooks.
    res.status(200).json({ success: true, data: { weeklyAvailability: provider.weeklyAvailability } });
  } catch (err) {
    next(err);
  }
}

export async function upsertAvailabilityException(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const provider = await loadOwnProfile(req.user!.id);
    const payload = req.body as UpsertAvailabilityExceptionInput;

    // Replace any existing exception on the same calendar date (idempotent upsert).
    const sameDay = (d: Date) =>
      d.getUTCFullYear() === payload.date.getUTCFullYear() &&
      d.getUTCMonth() === payload.date.getUTCMonth() &&
      d.getUTCDate() === payload.date.getUTCDate();

    provider.availabilityExceptions = provider.availabilityExceptions.filter(
      (ex) => !sameDay(ex.date),
    ) as typeof provider.availabilityExceptions;
    provider.availabilityExceptions.push(payload as never);

    await provider.save();
    res.status(200).json({
      success: true,
      data: { availabilityExceptions: provider.availabilityExceptions },
    });
  } catch (err) {
    next(err);
  }
}

export async function setHolidayMode(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const provider = await loadOwnProfile(req.user!.id);
    const { holidayMode } = req.body as SetHolidayModeInput;
    provider.holidayMode = holidayMode;
    await provider.save();
    res.status(200).json({ success: true, data: { holidayMode: provider.holidayMode } });
  } catch (err) {
    next(err);
  }
}
