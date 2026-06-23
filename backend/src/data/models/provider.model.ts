/**
 * Provider model.
 *
 * Holds the professional profile for a service provider: specialty taxonomy,
 * verifiable credential documents, rating aggregates, geo location for
 * proximity search, consultation pricing, the per-platform commission override,
 * and the full availability matrix:
 *   - `weeklyAvailability`: recurring weekday windows (with intra-window breaks),
 *   - `availabilityExceptions`: date-specific overrides / one-off blocks,
 *   - `holidayMode`: a hard global switch that makes the provider unbookable.
 *
 * The owning identity lives in the `User` collection (`user` ref, role=provider).
 */

import { Schema, model, Types, type Document, type Model } from 'mongoose';
import {
  ConsultationMode,
  CONSULTATION_MODES,
  VerificationStatus,
  VERIFICATION_STATUSES,
  Weekday,
  WEEKDAYS,
  SUPPORTED_CURRENCIES,
  type SupportedCurrency,
} from '../../shared/enums';
import { isHHmm, hhmmToMinutes, isLngLat } from '../../shared/validators';
import type { IGeoPoint } from './user.model';

/** A single bookable window on a recurring weekday, with optional breaks. */
export interface IAvailabilityWindow {
  weekday: Weekday;
  /** Inclusive start, `HH:mm` 24h. */
  startTime: string;
  /** Exclusive end, `HH:mm` 24h, strictly greater than `startTime`. */
  endTime: string;
  /** Non-overlapping break sub-windows carved out of the parent window. */
  breaks: { startTime: string; endTime: string }[];
}

/** A date-specific override that blocks or replaces recurring availability. */
export interface IAvailabilityException {
  /** Calendar date (UTC midnight) the exception applies to. */
  date: Date;
  /** When true the whole day is blocked regardless of recurring windows. */
  isFullDayOff: boolean;
  /** Optional custom windows that replace recurring ones for this date. */
  windows: { startTime: string; endTime: string }[];
  reason?: string;
}

export interface IVerificationDocument {
  docType: string;
  fileUrl: string;
  uploadedAt: Date;
  reviewedAt?: Date;
  isApproved: boolean;
}

export interface IProvider extends Document<Types.ObjectId> {
  user: Types.ObjectId;
  displayName: string;
  headline?: string;
  bio?: string;
  specialties: string[];
  primarySpecialty: string;
  yearsOfExperience: number;
  languages: string[];
  consultationModes: ConsultationMode[];
  pricing: {
    onlineFee: number;
    clinicFee: number;
    currency: SupportedCurrency;
    sessionDurationMinutes: number;
  };
  clinicLocation?: IGeoPoint;
  clinicAddress?: string;
  rating: { average: number; count: number };
  verificationStatus: VerificationStatus;
  verificationDocuments: IVerificationDocument[];
  /** Per-provider commission override (fraction 0–1). Falls back to platform default when null. */
  commissionRateOverride?: number | null;
  weeklyAvailability: IAvailabilityWindow[];
  availabilityExceptions: IAvailabilityException[];
  holidayMode: boolean;
  bookingLeadTimeMinutes: number;
  isAcceptingNewClients: boolean;
  totalCompletedAppointments: number;
  createdAt: Date;
  updatedAt: Date;
}

export type IProviderModel = Model<IProvider>;

/** Reusable validator: a time sub-range where end strictly follows start. */
function validTimeRange(this: { startTime: string; endTime: string }): boolean {
  if (!isHHmm(this.startTime) || !isHHmm(this.endTime)) return false;
  return hhmmToMinutes(this.endTime) > hhmmToMinutes(this.startTime);
}

const TimeRangeSchema = new Schema(
  {
    startTime: {
      type: String,
      required: true,
      validate: { validator: isHHmm, message: 'startTime must be HH:mm (24h).' },
    },
    endTime: {
      type: String,
      required: true,
      validate: { validator: isHHmm, message: 'endTime must be HH:mm (24h).' },
    },
  },
  { _id: false },
);
TimeRangeSchema.pre('validate', function (next) {
  if (!validTimeRange.call(this as { startTime: string; endTime: string })) {
    return next(new Error('endTime must be strictly after startTime.'));
  }
  next();
});

const AvailabilityWindowSchema = new Schema<IAvailabilityWindow>(
  {
    weekday: {
      type: Number,
      required: true,
      enum: { values: WEEKDAYS, message: '{VALUE} is not a valid weekday (0–6).' },
    },
    startTime: {
      type: String,
      required: true,
      validate: { validator: isHHmm, message: 'startTime must be HH:mm (24h).' },
    },
    endTime: {
      type: String,
      required: true,
      validate: { validator: isHHmm, message: 'endTime must be HH:mm (24h).' },
    },
    breaks: { type: [TimeRangeSchema], default: [] },
  },
  { _id: false },
);
AvailabilityWindowSchema.pre('validate', function (next) {
  const win = this as unknown as IAvailabilityWindow;
  if (hhmmToMinutes(win.endTime) <= hhmmToMinutes(win.startTime)) {
    return next(new Error('Availability window endTime must be strictly after startTime.'));
  }
  // Every break must sit fully inside the parent window.
  const winStart = hhmmToMinutes(win.startTime);
  const winEnd = hhmmToMinutes(win.endTime);
  for (const br of win.breaks ?? []) {
    const bStart = hhmmToMinutes(br.startTime);
    const bEnd = hhmmToMinutes(br.endTime);
    if (bStart < winStart || bEnd > winEnd) {
      return next(new Error('Break windows must fall within their parent availability window.'));
    }
  }
  next();
});

const AvailabilityExceptionSchema = new Schema<IAvailabilityException>(
  {
    date: { type: Date, required: true },
    isFullDayOff: { type: Boolean, default: true, required: true },
    windows: { type: [TimeRangeSchema], default: [] },
    reason: { type: String, trim: true, maxlength: 280 },
  },
  { _id: false },
);

const VerificationDocumentSchema = new Schema<IVerificationDocument>(
  {
    docType: {
      type: String,
      required: true,
      trim: true,
      maxlength: 80,
    },
    fileUrl: { type: String, required: true, trim: true, maxlength: 2048 },
    uploadedAt: { type: Date, default: () => new Date(), required: true },
    reviewedAt: { type: Date },
    isApproved: { type: Boolean, default: false, required: true },
  },
  { _id: false },
);

const GeoPointSchema = new Schema<IGeoPoint>(
  {
    type: { type: String, enum: ['Point'], default: 'Point', required: true },
    coordinates: {
      type: [Number],
      required: true,
      validate: {
        validator: isLngLat,
        message: 'clinicLocation.coordinates must be a valid [longitude, latitude] pair.',
      },
    },
  },
  { _id: false },
);

const ProviderSchema = new Schema<IProvider, IProviderModel>(
  {
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'A provider must reference an owning user.'],
      unique: true,
    },
    displayName: {
      type: String,
      required: [true, 'displayName is required.'],
      trim: true,
      minlength: 2,
      maxlength: 120,
    },
    headline: { type: String, trim: true, maxlength: 160 },
    bio: { type: String, trim: true, maxlength: 4000 },
    specialties: {
      type: [{ type: String, trim: true, lowercase: true, maxlength: 80 }],
      required: true,
      validate: {
        validator: (arr: string[]) => Array.isArray(arr) && arr.length > 0 && arr.length <= 20,
        message: 'A provider must declare between 1 and 20 specialties.',
      },
    },
    primarySpecialty: {
      type: String,
      required: [true, 'primarySpecialty is required.'],
      trim: true,
      lowercase: true,
      maxlength: 80,
      index: true,
    },
    yearsOfExperience: {
      type: Number,
      default: 0,
      min: [0, 'yearsOfExperience cannot be negative.'],
      max: [80, 'yearsOfExperience is unrealistically high.'],
    },
    languages: {
      type: [{ type: String, trim: true, lowercase: true, maxlength: 40 }],
      default: ['en'],
    },
    consultationModes: {
      type: [{ type: String, enum: CONSULTATION_MODES }],
      required: true,
      validate: {
        validator: (arr: string[]) => Array.isArray(arr) && arr.length > 0,
        message: 'At least one consultation mode (online/clinic) is required.',
      },
    },
    pricing: {
      onlineFee: {
        type: Number,
        default: 0,
        min: [0, 'onlineFee cannot be negative.'],
      },
      clinicFee: {
        type: Number,
        default: 0,
        min: [0, 'clinicFee cannot be negative.'],
      },
      currency: {
        type: String,
        enum: { values: SUPPORTED_CURRENCIES, message: '{VALUE} is not a supported currency.' },
        required: true,
        default: 'USD',
      },
      sessionDurationMinutes: {
        type: Number,
        default: 30,
        min: [5, 'sessionDurationMinutes must be at least 5 minutes.'],
        max: [480, 'sessionDurationMinutes cannot exceed 8 hours.'],
      },
    },
    clinicLocation: { type: GeoPointSchema, required: false },
    clinicAddress: { type: String, trim: true, maxlength: 300 },
    rating: {
      average: {
        type: Number,
        default: 0,
        min: [0, 'rating.average cannot be below 0.'],
        max: [5, 'rating.average cannot exceed 5.'],
      },
      count: {
        type: Number,
        default: 0,
        min: [0, 'rating.count cannot be negative.'],
      },
    },
    verificationStatus: {
      type: String,
      enum: { values: VERIFICATION_STATUSES, message: '{VALUE} is not a valid verification status.' },
      default: VerificationStatus.UNSUBMITTED,
      required: true,
      index: true,
    },
    verificationDocuments: { type: [VerificationDocumentSchema], default: [] },
    commissionRateOverride: {
      type: Number,
      default: null,
      min: [0, 'commissionRateOverride cannot be below 0.'],
      max: [1, 'commissionRateOverride is a fraction and cannot exceed 1.'],
    },
    weeklyAvailability: { type: [AvailabilityWindowSchema], default: [] },
    availabilityExceptions: { type: [AvailabilityExceptionSchema], default: [] },
    holidayMode: { type: Boolean, default: false, required: true, index: true },
    bookingLeadTimeMinutes: {
      type: Number,
      default: 60,
      min: [0, 'bookingLeadTimeMinutes cannot be negative.'],
      max: [20160, 'bookingLeadTimeMinutes cannot exceed 14 days.'],
    },
    isAcceptingNewClients: { type: Boolean, default: true, required: true },
    totalCompletedAppointments: {
      type: Number,
      default: 0,
      min: [0, 'totalCompletedAppointments cannot be negative.'],
    },
  },
  {
    timestamps: true,
    strict: 'throw',
    minimize: false,
    versionKey: false,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

// Guard: if `clinic` is an offered mode, a clinic location must be present.
ProviderSchema.pre('validate', function (next) {
  const offersClinic = (this.consultationModes ?? []).includes(ConsultationMode.CLINIC);
  if (offersClinic && !this.clinicLocation) {
    return next(new Error('clinicLocation is required when offering clinic consultations.'));
  }
  next();
});

// ---------------------------------------------------------------------------
// Indexes
// ---------------------------------------------------------------------------
// Core marketplace search: specialty + verification + rating, newest-first.
ProviderSchema.index(
  { primarySpecialty: 1, verificationStatus: 1, 'rating.average': -1 },
  { name: 'idx_provider_search' },
);
// Multikey index to filter across all declared specialties.
ProviderSchema.index({ specialties: 1 }, { name: 'idx_provider_specialties' });
// Proximity search against clinic location.
ProviderSchema.index({ clinicLocation: '2dsphere' }, { name: 'geo_provider_clinic' });
// "Available now" style filtering: bookable, not on holiday, accepting clients.
ProviderSchema.index(
  { holidayMode: 1, isAcceptingNewClients: 1, verificationStatus: 1 },
  { name: 'idx_provider_bookable' },
);
// Sort/lead boards by rating.
ProviderSchema.index({ 'rating.average': -1, 'rating.count': -1 }, { name: 'idx_provider_rating' });
// Full-text search over name + bio for free-text discovery.
ProviderSchema.index(
  { displayName: 'text', bio: 'text', headline: 'text' },
  { name: 'text_provider_profile', weights: { displayName: 5, headline: 3, bio: 1 } },
);

export const Provider = model<IProvider, IProviderModel>('Provider', ProviderSchema);
export default Provider;
