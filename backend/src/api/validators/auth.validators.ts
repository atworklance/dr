/**
 * Zod request validators for registration & authentication endpoints.
 */

import { z } from 'zod';
import {
  CONSULTATION_MODES,
  GENDERS,
  SUPPORTED_CURRENCIES,
} from '../../shared/enums';
import { currency, geoPoint } from './common.validators';

const password = z
  .string()
  .min(8, 'Password must be at least 8 characters.')
  .max(128, 'Password cannot exceed 128 characters.')
  .regex(/[A-Za-z]/, 'Password must contain a letter.')
  .regex(/\d/, 'Password must contain a digit.');

const e164 = z
  .string()
  .regex(/^\+[1-9]\d{6,14}$/, 'Phone must be E.164 format, e.g. +14155552671.');

/** Fields common to both client and provider registration. */
const baseRegistration = {
  firstName: z.string().trim().min(1).max(60),
  lastName: z.string().trim().min(1).max(60),
  email: z.string().trim().toLowerCase().email('Invalid email address.').max(254),
  phone: e164.optional(),
  password,
  gender: z.enum(GENDERS as unknown as [string, ...string[]]).optional(),
  dateOfBirth: z.coerce.date().max(new Date(), 'dateOfBirth must be in the past.').optional(),
  location: geoPoint.optional(),
  preferredLocale: z.string().trim().toLowerCase().max(10).optional(),
};

export const registerClientSchema = z.object(baseRegistration).strict();
export type RegisterClientInput = z.infer<typeof registerClientSchema>;

export const registerProviderSchema = z
  .object({
    ...baseRegistration,
    displayName: z.string().trim().min(2).max(120),
    headline: z.string().trim().max(160).optional(),
    bio: z.string().trim().max(4000).optional(),
    primarySpecialty: z.string().trim().toLowerCase().min(1).max(80),
    specialties: z
      .array(z.string().trim().toLowerCase().min(1).max(80))
      .min(1, 'At least one specialty is required.')
      .max(20),
    yearsOfExperience: z.number().int().min(0).max(80).optional(),
    languages: z.array(z.string().trim().toLowerCase().max(40)).max(20).optional(),
    consultationModes: z
      .array(z.enum(CONSULTATION_MODES as unknown as [string, ...string[]]))
      .min(1, 'At least one consultation mode is required.'),
    pricing: z.object({
      onlineFee: z.number().int('Fees are stored in integer minor units.').min(0),
      clinicFee: z.number().int('Fees are stored in integer minor units.').min(0),
      currency: currency.default(SUPPORTED_CURRENCIES[0]),
      sessionDurationMinutes: z.number().int().min(5).max(480),
    }),
    clinicLocation: geoPoint.optional(),
    clinicAddress: z.string().trim().max(300).optional(),
  })
  .strict()
  .superRefine((data, ctx) => {
    // `primarySpecialty` must be one of the declared specialties.
    if (!data.specialties.includes(data.primarySpecialty)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['primarySpecialty'],
        message: 'primarySpecialty must be included in specialties.',
      });
    }
    // Offering clinic consultations requires a clinic location.
    if (data.consultationModes.includes('clinic') && !data.clinicLocation) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['clinicLocation'],
        message: 'clinicLocation is required when offering clinic consultations.',
      });
    }
  });
export type RegisterProviderInput = z.infer<typeof registerProviderSchema>;

export const loginSchema = z
  .object({
    email: z.string().trim().toLowerCase().email().max(254),
    password: z.string().min(1, 'Password is required.'),
  })
  .strict();
export type LoginInput = z.infer<typeof loginSchema>;
