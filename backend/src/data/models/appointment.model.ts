/**
 * Appointment model.
 *
 * Maps a client to a provider for a concrete time window, tracks the full
 * appointment + payment state machine, the chosen consultation mode, and an
 * encrypted client-notes payload (AES-256-GCM at rest). It also carries the
 * real-time session metadata (chat room + video channel/token references) used
 * by the Socket.io and Agora/WebRTC engines.
 *
 * Concurrency: a partial unique index on (provider, timeWindow.start) for
 * "live" statuses prevents two confirmed bookings from colliding on the same
 * provider slot — the database is the final arbiter against race conditions.
 */

import { Schema, model, Types, type Document, type Model } from 'mongoose';
import {
  AppointmentStatus,
  APPOINTMENT_STATUSES,
  ConsultationMode,
  CONSULTATION_MODES,
  PaymentStatus,
  PAYMENT_STATUSES,
  SUPPORTED_CURRENCIES,
  type SupportedCurrency,
} from '../../shared/enums';
import { encryptField, decryptField, type EncryptedPayload } from '../../shared/crypto';

const EncryptedPayloadSchema = new Schema<EncryptedPayload>(
  {
    iv: { type: String, required: true },
    content: { type: String, required: true },
    authTag: { type: String, required: true },
  },
  { _id: false },
);

export interface IAppointment extends Document<Types.ObjectId> {
  client: Types.ObjectId;
  provider: Types.ObjectId;
  consultationMode: ConsultationMode;
  timeWindow: { start: Date; end: Date };
  durationMinutes: number;
  status: AppointmentStatus;
  paymentStatus: PaymentStatus;
  price: { amount: number; currency: SupportedCurrency };
  commissionAmount: number;
  /** Encrypted client-supplied notes envelope; never stored in plaintext. */
  encryptedNotes?: EncryptedPayload;
  cancellationReason?: string;
  cancelledBy?: Types.ObjectId;
  session: {
    chatRoomId?: string;
    videoChannelName?: string;
    videoProvider?: string;
    startedAt?: Date;
    endedAt?: Date;
  };
  rescheduledFrom?: Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
  /** Plaintext setter for client notes (transparently encrypts). */
  setNotes(plaintext: string): void;
  /** Plaintext getter for client notes (transparently decrypts). */
  getNotes(): string | null;
}

export type IAppointmentModel = Model<IAppointment>;

/** Statuses that occupy a provider's calendar slot and must not double-book. */
const LIVE_STATUSES: AppointmentStatus[] = [
  AppointmentStatus.PENDING_PAYMENT,
  AppointmentStatus.CONFIRMED,
  AppointmentStatus.IN_PROGRESS,
];

const AppointmentSchema = new Schema<IAppointment, IAppointmentModel>(
  {
    client: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'client is required.'],
      index: true,
    },
    provider: {
      type: Schema.Types.ObjectId,
      ref: 'Provider',
      required: [true, 'provider is required.'],
      index: true,
    },
    consultationMode: {
      type: String,
      enum: { values: CONSULTATION_MODES, message: '{VALUE} is not a valid consultation mode.' },
      required: true,
    },
    timeWindow: {
      start: { type: Date, required: [true, 'timeWindow.start is required.'] },
      end: { type: Date, required: [true, 'timeWindow.end is required.'] },
    },
    durationMinutes: {
      type: Number,
      required: true,
      min: [5, 'durationMinutes must be at least 5 minutes.'],
      max: [480, 'durationMinutes cannot exceed 8 hours.'],
    },
    status: {
      type: String,
      enum: { values: APPOINTMENT_STATUSES, message: '{VALUE} is not a valid appointment status.' },
      default: AppointmentStatus.PENDING_PAYMENT,
      required: true,
      index: true,
    },
    paymentStatus: {
      type: String,
      enum: { values: PAYMENT_STATUSES, message: '{VALUE} is not a valid payment status.' },
      default: PaymentStatus.UNPAID,
      required: true,
      index: true,
    },
    price: {
      amount: {
        type: Number,
        required: true,
        min: [0, 'price.amount cannot be negative.'],
      },
      currency: {
        type: String,
        enum: { values: SUPPORTED_CURRENCIES, message: '{VALUE} is not a supported currency.' },
        required: true,
        default: 'USD',
      },
    },
    commissionAmount: {
      type: Number,
      default: 0,
      min: [0, 'commissionAmount cannot be negative.'],
    },
    encryptedNotes: { type: EncryptedPayloadSchema, required: false, select: false },
    cancellationReason: { type: String, trim: true, maxlength: 500 },
    cancelledBy: { type: Schema.Types.ObjectId, ref: 'User' },
    session: {
      chatRoomId: { type: String, trim: true, maxlength: 120 },
      videoChannelName: { type: String, trim: true, maxlength: 120 },
      videoProvider: { type: String, trim: true, maxlength: 40, default: 'agora' },
      startedAt: { type: Date },
      endedAt: { type: Date },
    },
    rescheduledFrom: { type: Schema.Types.ObjectId, ref: 'Appointment' },
  },
  {
    timestamps: true,
    strict: 'throw',
    minimize: false,
    // `__v` retained intentionally: optimisticConcurrency relies on the version key
    // to version-guard writes for safe state transitions.
    optimisticConcurrency: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

// Validate temporal + commission coherence before any write.
AppointmentSchema.pre('validate', function (next) {
  if (this.timeWindow?.start && this.timeWindow?.end) {
    if (this.timeWindow.end.getTime() <= this.timeWindow.start.getTime()) {
      return next(new Error('timeWindow.end must be strictly after timeWindow.start.'));
    }
  }
  if (this.price && this.commissionAmount > this.price.amount) {
    return next(new Error('commissionAmount cannot exceed the appointment price.'));
  }
  next();
});

// ---------------------------------------------------------------------------
// Encrypted notes accessors
// ---------------------------------------------------------------------------
AppointmentSchema.methods.setNotes = function (this: IAppointment, plaintext: string): void {
  if (plaintext == null || plaintext === '') {
    this.encryptedNotes = undefined;
    return;
  }
  if (plaintext.length > 5000) {
    throw new Error('Client notes cannot exceed 5000 characters.');
  }
  this.encryptedNotes = encryptField(plaintext);
};

AppointmentSchema.methods.getNotes = function (this: IAppointment): string | null {
  if (!this.encryptedNotes) return null;
  return decryptField(this.encryptedNotes);
};

// ---------------------------------------------------------------------------
// Indexes
// ---------------------------------------------------------------------------
// Provider calendar lookups (their agenda ordered by time).
AppointmentSchema.index({ provider: 1, 'timeWindow.start': 1 }, { name: 'idx_appt_provider_time' });
// Client history / upcoming list.
AppointmentSchema.index({ client: 1, 'timeWindow.start': -1 }, { name: 'idx_appt_client_time' });
// Operational dashboards filter by status over time.
AppointmentSchema.index({ status: 1, 'timeWindow.start': 1 }, { name: 'idx_appt_status_time' });
// Settlement / finance queries.
AppointmentSchema.index({ paymentStatus: 1, updatedAt: -1 }, { name: 'idx_appt_payment' });
// Hard double-booking guard: one live appointment per provider slot-start.
AppointmentSchema.index(
  { provider: 1, 'timeWindow.start': 1 },
  {
    name: 'uniq_provider_live_slot',
    unique: true,
    partialFilterExpression: { status: { $in: LIVE_STATUSES } },
  },
);

export const Appointment = model<IAppointment, IAppointmentModel>('Appointment', AppointmentSchema);
export default Appointment;
