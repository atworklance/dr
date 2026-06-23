/**
 * Wallet model.
 *
 * One wallet per platform participant (provider or client). Tracks three
 * distinct balances — `available` (withdrawable), `pending` (clearing), and
 * `escrow` (held against in-flight appointments) — alongside an append-only
 * ledger of movements and the queue of withdrawal/settlement requests that the
 * revenue dashboard and admin hub act upon.
 *
 * Money is stored in MINOR units (integer cents) to eliminate floating-point
 * drift; never persist fractional currency in the balance fields.
 */

import { Schema, model, Types, type Document, type Model } from 'mongoose';
import {
  SUPPORTED_CURRENCIES,
  type SupportedCurrency,
  WalletTxnType,
  WALLET_TXN_TYPES,
  WalletTxnStatus,
  WALLET_TXN_STATUSES,
  WithdrawalStatus,
  WITHDRAWAL_STATUSES,
} from '../../shared/enums';

/** An immutable double-entry-style ledger movement. */
export interface IWalletTransaction {
  _id: Types.ObjectId;
  type: WalletTxnType;
  status: WalletTxnStatus;
  /** Signed minor-unit amount (positive = inflow, negative = outflow). */
  amount: number;
  /** Resulting `available` balance immediately after this movement (audit trail). */
  balanceAfter: number;
  currency: SupportedCurrency;
  appointment?: Types.ObjectId;
  reference?: string;
  description?: string;
  createdAt: Date;
}

/** A provider-initiated payout request moving funds off-platform. */
export interface IWithdrawalRequest {
  _id: Types.ObjectId;
  amount: number;
  currency: SupportedCurrency;
  status: WithdrawalStatus;
  payoutMethod: string;
  payoutReference?: string;
  requestedAt: Date;
  processedAt?: Date;
  rejectionReason?: string;
}

export interface IWallet extends Document<Types.ObjectId> {
  owner: Types.ObjectId;
  ownerModel: 'User';
  currency: SupportedCurrency;
  balances: {
    available: number;
    pending: number;
    escrow: number;
  };
  lifetimeEarnings: number;
  lifetimeWithdrawn: number;
  transactions: Types.DocumentArray<IWalletTransaction>;
  withdrawalRequests: Types.DocumentArray<IWithdrawalRequest>;
  isFrozen: boolean;
  createdAt: Date;
  updatedAt: Date;
  /** Virtual: total funds across all three balance buckets. */
  totalBalance: number;
}

export type IWalletModel = Model<IWallet>;

const WalletTransactionSchema = new Schema<IWalletTransaction>(
  {
    type: {
      type: String,
      enum: { values: WALLET_TXN_TYPES, message: '{VALUE} is not a valid transaction type.' },
      required: true,
    },
    status: {
      type: String,
      enum: { values: WALLET_TXN_STATUSES, message: '{VALUE} is not a valid transaction status.' },
      default: WalletTxnStatus.PENDING,
      required: true,
    },
    amount: {
      type: Number,
      required: true,
      validate: {
        validator: Number.isInteger,
        message: 'amount must be an integer in minor currency units (cents).',
      },
    },
    balanceAfter: {
      type: Number,
      required: true,
      min: [0, 'balanceAfter cannot be negative.'],
      validate: {
        validator: Number.isInteger,
        message: 'balanceAfter must be an integer in minor currency units (cents).',
      },
    },
    currency: {
      type: String,
      enum: { values: SUPPORTED_CURRENCIES, message: '{VALUE} is not a supported currency.' },
      required: true,
    },
    appointment: { type: Schema.Types.ObjectId, ref: 'Appointment' },
    reference: { type: String, trim: true, maxlength: 120 },
    description: { type: String, trim: true, maxlength: 280 },
  },
  { _id: true, timestamps: { createdAt: true, updatedAt: false } },
);

const WithdrawalRequestSchema = new Schema<IWithdrawalRequest>(
  {
    amount: {
      type: Number,
      required: true,
      min: [1, 'Withdrawal amount must be a positive minor-unit value.'],
      validate: {
        validator: Number.isInteger,
        message: 'amount must be an integer in minor currency units (cents).',
      },
    },
    currency: {
      type: String,
      enum: { values: SUPPORTED_CURRENCIES, message: '{VALUE} is not a supported currency.' },
      required: true,
    },
    status: {
      type: String,
      enum: { values: WITHDRAWAL_STATUSES, message: '{VALUE} is not a valid withdrawal status.' },
      default: WithdrawalStatus.REQUESTED,
      required: true,
    },
    payoutMethod: { type: String, required: true, trim: true, maxlength: 80 },
    payoutReference: { type: String, trim: true, maxlength: 160 },
    requestedAt: { type: Date, default: () => new Date(), required: true },
    processedAt: { type: Date },
    rejectionReason: { type: String, trim: true, maxlength: 500 },
  },
  { _id: true },
);

const WalletSchema = new Schema<IWallet, IWalletModel>(
  {
    owner: {
      type: Schema.Types.ObjectId,
      required: [true, 'A wallet must reference an owner.'],
      refPath: 'ownerModel',
    },
    ownerModel: {
      type: String,
      required: true,
      enum: ['User'],
      default: 'User',
    },
    currency: {
      type: String,
      enum: { values: SUPPORTED_CURRENCIES, message: '{VALUE} is not a supported currency.' },
      required: true,
      default: 'USD',
    },
    balances: {
      available: {
        type: Number,
        default: 0,
        min: [0, 'available balance cannot be negative.'],
        validate: { validator: Number.isInteger, message: 'available must be an integer (cents).' },
      },
      pending: {
        type: Number,
        default: 0,
        min: [0, 'pending balance cannot be negative.'],
        validate: { validator: Number.isInteger, message: 'pending must be an integer (cents).' },
      },
      escrow: {
        type: Number,
        default: 0,
        min: [0, 'escrow balance cannot be negative.'],
        validate: { validator: Number.isInteger, message: 'escrow must be an integer (cents).' },
      },
    },
    lifetimeEarnings: {
      type: Number,
      default: 0,
      min: [0, 'lifetimeEarnings cannot be negative.'],
    },
    lifetimeWithdrawn: {
      type: Number,
      default: 0,
      min: [0, 'lifetimeWithdrawn cannot be negative.'],
    },
    transactions: { type: [WalletTransactionSchema], default: [] },
    withdrawalRequests: { type: [WithdrawalRequestSchema], default: [] },
    isFrozen: { type: Boolean, default: false, required: true },
  },
  {
    timestamps: true,
    strict: 'throw',
    minimize: false,
    // `__v` retained intentionally: optimisticConcurrency relies on the version key
    // to protect balance mutations from lost updates.
    optimisticConcurrency: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

// ---------------------------------------------------------------------------
// Virtuals
// ---------------------------------------------------------------------------
WalletSchema.virtual('totalBalance').get(function (this: IWallet): number {
  return this.balances.available + this.balances.pending + this.balances.escrow;
});

// ---------------------------------------------------------------------------
// Indexes
// ---------------------------------------------------------------------------
// Exactly one wallet per owner.
WalletSchema.index({ owner: 1 }, { unique: true, name: 'uniq_wallet_owner' });
// Admin queue: surface wallets with outstanding withdrawal requests by state.
WalletSchema.index({ 'withdrawalRequests.status': 1 }, { name: 'idx_wallet_withdrawal_status' });
// Reconciliation lookups by transaction reference.
WalletSchema.index(
  { 'transactions.reference': 1 },
  {
    name: 'idx_wallet_txn_reference',
    partialFilterExpression: { 'transactions.reference': { $type: 'string' } },
  },
);

export const Wallet = model<IWallet, IWalletModel>('Wallet', WalletSchema);
export default Wallet;
