/**
 * Platform settings domain service.
 *
 * Provides find-or-create access to the singleton PlatformSettings document and
 * a convenience reader for the effective platform commission rate (seeded from
 * the env default on first access). Consumed by the booking pipeline and the
 * admin commission controls.
 */

import type { Types } from 'mongoose';
import { PlatformSettings, type IPlatformSettings } from '../../data/models';
import { config } from '../../config';

const SETTINGS_KEY = 'platform' as const;

export async function getPlatformSettings(): Promise<IPlatformSettings> {
  const existing = await PlatformSettings.findOne({ key: SETTINGS_KEY });
  if (existing) return existing;
  return PlatformSettings.create({
    key: SETTINGS_KEY,
    defaultCommissionRate: config.defaultCommissionRate,
  });
}

/** Effective platform commission fraction (0–1). */
export async function getPlatformCommissionRate(): Promise<number> {
  const settings = await getPlatformSettings();
  return settings.defaultCommissionRate;
}

export async function setPlatformCommissionRate(
  rate: number,
  updatedBy?: Types.ObjectId,
): Promise<IPlatformSettings> {
  const settings = await getPlatformSettings();
  settings.defaultCommissionRate = rate;
  if (updatedBy) settings.updatedBy = updatedBy;
  await settings.save();
  return settings;
}
