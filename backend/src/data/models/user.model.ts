/**
 * User (Client) model.
 *
 * Represents an end-user / client of the Dr.Plus marketplace. Providers and
 * admins authenticate through this same identity collection (discriminated by
 * `role`), but provider-specific professional data lives on the dedicated
 * `Provider` profile referenced by `providerProfile`.
 *
 * Security notes:
 *  - `passwordHash` is `select: false`; it is never returned unless explicitly
 *    requested, and is stripped from all JSON/object serialisations.
 *  - Geo location is stored as GeoJSON to power proximity search via 2dsphere.
 */

import { Schema, model, Types, type Document, type Model } from 'mongoose';
import {
  AccountStatus,
  ACCOUNT_STATUSES,
  Gender,
  GENDERS,
  UserRole,
  USER_ROLES,
} from '../../shared/enums';
import { isEmail, isE164Phone, isLngLat } from '../../shared/validators';

export interface IGeoPoint {
  type: 'Point';
  /** GeoJSON ordering: [longitude, latitude]. */
  coordinates: [number, number];
}

export interface IUser extends Document<Types.ObjectId> {
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  passwordHash: string;
  role: UserRole;
  status: AccountStatus;
  gender: Gender;
  dateOfBirth?: Date;
  avatarUrl?: string;
  location?: IGeoPoint;
  address?: {
    line1?: string;
    city?: string;
    state?: string;
    country?: string;
    postalCode?: string;
  };
  isEmailVerified: boolean;
  isPhoneVerified: boolean;
  savedProviders: Types.ObjectId[];
  providerProfile?: Types.ObjectId;
  wallet?: Types.ObjectId;
  preferredLocale: string;
  lastLoginAt?: Date;
  createdAt: Date;
  updatedAt: Date;
  /** Virtual: convenience full-name accessor. */
  fullName: string;
}

export type IUserModel = Model<IUser>;

const GeoPointSchema = new Schema<IGeoPoint>(
  {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
      required: true,
    },
    coordinates: {
      type: [Number],
      required: true,
      validate: {
        validator: isLngLat,
        message: 'location.coordinates must be a valid [longitude, latitude] pair.',
      },
    },
  },
  { _id: false },
);

const UserSchema = new Schema<IUser, IUserModel>(
  {
    firstName: {
      type: String,
      required: [true, 'First name is required.'],
      trim: true,
      minlength: [1, 'First name cannot be empty.'],
      maxlength: [60, 'First name cannot exceed 60 characters.'],
    },
    lastName: {
      type: String,
      required: [true, 'Last name is required.'],
      trim: true,
      minlength: [1, 'Last name cannot be empty.'],
      maxlength: [60, 'Last name cannot exceed 60 characters.'],
    },
    email: {
      type: String,
      required: [true, 'Email is required.'],
      trim: true,
      lowercase: true,
      maxlength: [254, 'Email cannot exceed 254 characters.'],
      validate: { validator: isEmail, message: '{VALUE} is not a valid email address.' },
    },
    phone: {
      type: String,
      trim: true,
      validate: {
        validator: (v: string) => v == null || v === '' || isE164Phone(v),
        message: '{VALUE} is not a valid E.164 phone number (e.g. +14155552671).',
      },
    },
    passwordHash: {
      type: String,
      required: [true, 'Password hash is required.'],
      select: false,
    },
    role: {
      type: String,
      enum: { values: USER_ROLES, message: '{VALUE} is not a supported role.' },
      default: UserRole.CLIENT,
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: { values: ACCOUNT_STATUSES, message: '{VALUE} is not a supported account status.' },
      default: AccountStatus.PENDING,
      required: true,
      index: true,
    },
    gender: {
      type: String,
      enum: { values: GENDERS, message: '{VALUE} is not a supported gender value.' },
      default: Gender.UNDISCLOSED,
      required: true,
    },
    dateOfBirth: {
      type: Date,
      validate: {
        validator: (v: Date) => v == null || v.getTime() < Date.now(),
        message: 'dateOfBirth must be in the past.',
      },
    },
    avatarUrl: {
      type: String,
      trim: true,
      maxlength: [2048, 'avatarUrl cannot exceed 2048 characters.'],
    },
    location: { type: GeoPointSchema, required: false },
    address: {
      line1: { type: String, trim: true, maxlength: 200 },
      city: { type: String, trim: true, maxlength: 100 },
      state: { type: String, trim: true, maxlength: 100 },
      country: { type: String, trim: true, maxlength: 100 },
      postalCode: { type: String, trim: true, maxlength: 20 },
    },
    isEmailVerified: { type: Boolean, default: false, required: true },
    isPhoneVerified: { type: Boolean, default: false, required: true },
    savedProviders: {
      type: [{ type: Schema.Types.ObjectId, ref: 'Provider' }],
      default: [],
    },
    providerProfile: { type: Schema.Types.ObjectId, ref: 'Provider' },
    wallet: { type: Schema.Types.ObjectId, ref: 'Wallet' },
    preferredLocale: {
      type: String,
      default: 'en',
      trim: true,
      lowercase: true,
      maxlength: [10, 'preferredLocale cannot exceed 10 characters.'],
    },
    lastLoginAt: { type: Date },
  },
  {
    timestamps: true,
    strict: 'throw', // reject documents containing fields absent from the schema.
    minimize: false,
    versionKey: false,
    toJSON: {
      virtuals: true,
      transform(_doc, ret: Record<string, unknown>) {
        delete ret.passwordHash;
        return ret;
      },
    },
    toObject: { virtuals: true },
  },
);

// ---------------------------------------------------------------------------
// Indexes
// ---------------------------------------------------------------------------
// Unique, case-insensitive email lookups for authentication.
UserSchema.index({ email: 1 }, { unique: true, name: 'uniq_user_email' });
// Sparse-unique phone: many users may omit a phone, but a present one is unique.
UserSchema.index(
  { phone: 1 },
  { unique: true, partialFilterExpression: { phone: { $type: 'string' } }, name: 'uniq_user_phone' },
);
// Proximity search for clients (and admin geo analytics).
UserSchema.index({ location: '2dsphere' }, { name: 'geo_user_location' });
// Admin dashboards filter by role + status + recency.
UserSchema.index({ role: 1, status: 1, createdAt: -1 }, { name: 'idx_user_role_status_created' });

// ---------------------------------------------------------------------------
// Virtuals
// ---------------------------------------------------------------------------
UserSchema.virtual('fullName').get(function (this: IUser): string {
  return `${this.firstName} ${this.lastName}`.trim();
});

export const User = model<IUser, IUserModel>('User', UserSchema);
export default User;
