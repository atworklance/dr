/**
 * PlatformSettings model — a singleton document holding platform-wide,
 * admin-tunable configuration. Currently the default commission rate applied to
 * appointments when a provider has no per-provider override.
 *
 * Enforced as a singleton via a unique `key` discriminator ('platform').
 */

import { Schema, model, Types, type Document, type Model } from 'mongoose';

export interface IPlatformSettings extends Document<Types.ObjectId> {
  key: 'platform';
  /** Default platform commission as a fraction (0–1). */
  defaultCommissionRate: number;
  updatedBy?: Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

export type IPlatformSettingsModel = Model<IPlatformSettings>;

const PlatformSettingsSchema = new Schema<IPlatformSettings, IPlatformSettingsModel>(
  {
    key: {
      type: String,
      required: true,
      unique: true,
      default: 'platform',
      enum: ['platform'],
    },
    defaultCommissionRate: {
      type: Number,
      required: true,
      default: 0.15,
      min: [0, 'defaultCommissionRate cannot be below 0.'],
      max: [1, 'defaultCommissionRate is a fraction and cannot exceed 1.'],
    },
    updatedBy: { type: Schema.Types.ObjectId, ref: 'User' },
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

export const PlatformSettings = model<IPlatformSettings, IPlatformSettingsModel>(
  'PlatformSettings',
  PlatformSettingsSchema,
);
export default PlatformSettings;
