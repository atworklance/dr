/**
 * Centralised domain enumerations shared across all Mongoose models.
 *
 * Keeping these in one place guarantees that schema `enum` validators, service
 * logic, and the API layer all reference an identical, single source of truth.
 * Every enum is declared `as const` and paired with a value-array so it can be
 * fed directly into Mongoose's `enum` validator.
 */

export const UserRole = {
  CLIENT: 'client',
  PROVIDER: 'provider',
  ADMIN: 'admin',
} as const;
export type UserRole = (typeof UserRole)[keyof typeof UserRole];
export const USER_ROLES = Object.values(UserRole);

export const AccountStatus = {
  PENDING: 'pending',
  ACTIVE: 'active',
  SUSPENDED: 'suspended',
  DEACTIVATED: 'deactivated',
} as const;
export type AccountStatus = (typeof AccountStatus)[keyof typeof AccountStatus];
export const ACCOUNT_STATUSES = Object.values(AccountStatus);

export const Gender = {
  MALE: 'male',
  FEMALE: 'female',
  OTHER: 'other',
  UNDISCLOSED: 'undisclosed',
} as const;
export type Gender = (typeof Gender)[keyof typeof Gender];
export const GENDERS = Object.values(Gender);

/** Lifecycle of a provider's verification / onboarding review. */
export const VerificationStatus = {
  UNSUBMITTED: 'unsubmitted',
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected',
} as const;
export type VerificationStatus = (typeof VerificationStatus)[keyof typeof VerificationStatus];
export const VERIFICATION_STATUSES = Object.values(VerificationStatus);

/** Where a consultation physically/logically happens. */
export const ConsultationMode = {
  ONLINE: 'online',
  CLINIC: 'clinic',
} as const;
export type ConsultationMode = (typeof ConsultationMode)[keyof typeof ConsultationMode];
export const CONSULTATION_MODES = Object.values(ConsultationMode);

/** Full appointment state machine. */
export const AppointmentStatus = {
  PENDING_PAYMENT: 'pending_payment',
  CONFIRMED: 'confirmed',
  IN_PROGRESS: 'in_progress',
  COMPLETED: 'completed',
  CANCELLED_BY_CLIENT: 'cancelled_by_client',
  CANCELLED_BY_PROVIDER: 'cancelled_by_provider',
  NO_SHOW: 'no_show',
  EXPIRED: 'expired',
} as const;
export type AppointmentStatus = (typeof AppointmentStatus)[keyof typeof AppointmentStatus];
export const APPOINTMENT_STATUSES = Object.values(AppointmentStatus);

/** Payment settlement state attached to an appointment. */
export const PaymentStatus = {
  UNPAID: 'unpaid',
  AUTHORIZED: 'authorized',
  IN_ESCROW: 'in_escrow',
  RELEASED: 'released',
  REFUNDED: 'refunded',
  FAILED: 'failed',
} as const;
export type PaymentStatus = (typeof PaymentStatus)[keyof typeof PaymentStatus];
export const PAYMENT_STATUSES = Object.values(PaymentStatus);

/** Days of the week for recurring availability windows (0 = Sunday). */
export const Weekday = {
  SUNDAY: 0,
  MONDAY: 1,
  TUESDAY: 2,
  WEDNESDAY: 3,
  THURSDAY: 4,
  FRIDAY: 5,
  SATURDAY: 6,
} as const;
export type Weekday = (typeof Weekday)[keyof typeof Weekday];
export const WEEKDAYS = Object.values(Weekday);

/** Wallet ledger movement classifications. */
export const WalletTxnType = {
  CREDIT: 'credit',
  DEBIT: 'debit',
  ESCROW_HOLD: 'escrow_hold',
  ESCROW_RELEASE: 'escrow_release',
  REFUND: 'refund',
  WITHDRAWAL: 'withdrawal',
  COMMISSION: 'commission',
  ADJUSTMENT: 'adjustment',
} as const;
export type WalletTxnType = (typeof WalletTxnType)[keyof typeof WalletTxnType];
export const WALLET_TXN_TYPES = Object.values(WalletTxnType);

export const WalletTxnStatus = {
  PENDING: 'pending',
  SETTLED: 'settled',
  FAILED: 'failed',
  REVERSED: 'reversed',
} as const;
export type WalletTxnStatus = (typeof WalletTxnStatus)[keyof typeof WalletTxnStatus];
export const WALLET_TXN_STATUSES = Object.values(WalletTxnStatus);

/** Lifecycle of a provider withdrawal / settlement request. */
export const WithdrawalStatus = {
  REQUESTED: 'requested',
  APPROVED: 'approved',
  PROCESSING: 'processing',
  PAID: 'paid',
  REJECTED: 'rejected',
  CANCELLED: 'cancelled',
} as const;
export type WithdrawalStatus = (typeof WithdrawalStatus)[keyof typeof WithdrawalStatus];
export const WITHDRAWAL_STATUSES = Object.values(WithdrawalStatus);

/** ISO-4217 currency codes the platform currently settles in. */
export const SUPPORTED_CURRENCIES = ['USD', 'EUR', 'GBP', 'AED', 'SAR', 'EGP', 'NGN'] as const;
export type SupportedCurrency = (typeof SUPPORTED_CURRENCIES)[number];
