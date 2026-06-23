// Types aligned with the Node.js / Mongoose data layer.

export type VerificationStatus =
  | 'unsubmitted'
  | 'pending'
  | 'approved'
  | 'rejected';

export type AccountStatus = 'pending' | 'active' | 'suspended' | 'deactivated';

export interface AdminUserRef {
  id?: string;
  _id?: string;
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  status: AccountStatus;
  isEmailVerified?: boolean;
  isPhoneVerified?: boolean;
  createdAt?: string;
}

export interface VerificationDocument {
  docType: string;
  fileUrl: string;
  uploadedAt: string;
  reviewedAt?: string;
  isApproved: boolean;
}

export interface ProviderPricing {
  onlineFee: number;
  clinicFee: number;
  currency: string;
  sessionDurationMinutes: number;
}

export interface ProviderRating {
  average: number;
  count: number;
}

export interface AdminProvider {
  id?: string;
  _id?: string;
  displayName: string;
  headline?: string;
  bio?: string;
  primarySpecialty: string;
  specialties: string[];
  yearsOfExperience?: number;
  verificationStatus: VerificationStatus;
  verificationDocuments: VerificationDocument[];
  commissionRateOverride: number | null;
  pricing: ProviderPricing;
  rating: ProviderRating;
  totalCompletedAppointments?: number;
  user: AdminUserRef | string;
  createdAt?: string;
}

export interface Paged<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

export interface PaymentBreakdown {
  count: number;
  gross: number;
  commission: number;
}

export interface WithdrawalBreakdown {
  count: number;
  amount: number;
}

export interface SystemMetrics {
  users: Record<string, number>;
  providersByVerification: Record<string, number>;
  appointmentsByStatus: Record<string, number>;
  payments: {
    byStatus: Record<string, PaymentBreakdown>;
    grossVolume: number;
    commissionEarned: number;
    releasedRevenue: number;
  };
  platformBalances: {
    available: number;
    pending: number;
    escrow: number;
    lifetimeEarnings: number;
    lifetimeWithdrawn: number;
  };
  withdrawalsByStatus: Record<string, WithdrawalBreakdown>;
}

export interface CommissionSettings {
  defaultCommissionRate: number;
}

export interface AuthUser {
  id?: string;
  _id?: string;
  firstName: string;
  lastName: string;
  email: string;
  role: string;
}

export interface AuthSession {
  token: string;
  user: AuthUser;
}
