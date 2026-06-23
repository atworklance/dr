/**
 * Admin domain service — the Platform Control Hub business logic.
 *
 * Provider verification (review docs, approve/reject), commission controls
 * (platform default + per-provider override), and system metrics aggregated
 * across providers, appointments, and wallets.
 */

import mongoose, { type FilterQuery } from 'mongoose';
import {
  Appointment,
  Provider,
  User,
  Wallet,
  type IProvider,
} from '../../data/models';
import {
  AccountStatus,
  VerificationStatus,
  VERIFICATION_STATUSES,
} from '../../shared/enums';
import { ApiError } from '../../shared/apiError';
import {
  getPlatformSettings,
  setPlatformCommissionRate,
} from './settings.service';

// ---------------------------------------------------------------------------
// Provider verification
// ---------------------------------------------------------------------------

export interface ListProvidersQuery {
  status?: string;
  q?: string;
  page: number;
  limit: number;
}

export async function listProviders(query: ListProvidersQuery): Promise<{
  items: Array<Record<string, unknown>>;
  total: number;
  page: number;
  limit: number;
}> {
  const filter: FilterQuery<IProvider> = {};
  if (query.status && VERIFICATION_STATUSES.includes(query.status as VerificationStatus)) {
    filter.verificationStatus = query.status;
  }
  if (query.q) {
    filter.displayName = { $regex: query.q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), $options: 'i' };
  }

  const skip = (query.page - 1) * query.limit;
  const [items, total] = await Promise.all([
    Provider.find(filter)
      .populate('user', 'firstName lastName email status isEmailVerified createdAt')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(query.limit)
      .lean(),
    Provider.countDocuments(filter),
  ]);

  return {
    items: items as Array<Record<string, unknown>>,
    total,
    page: query.page,
    limit: query.limit,
  };
}

export async function getProviderDetail(id: string): Promise<Record<string, unknown>> {
  const provider = await Provider.findById(id)
    .populate('user', 'firstName lastName email phone status isEmailVerified isPhoneVerified createdAt')
    .lean();
  if (!provider) {
    throw ApiError.notFound('Provider not found.');
  }
  return provider as Record<string, unknown>;
}

/**
 * Approve or reject a provider. Approval marks all submitted documents reviewed
 * and activates the owning user; rejection records the review without activating.
 * Runs in a transaction so provider + user move together.
 */
export async function setProviderVerification(
  id: string,
  status: 'approved' | 'rejected',
  reviewerId: mongoose.Types.ObjectId,
  note?: string,
): Promise<Record<string, unknown>> {
  const session = await mongoose.startSession();
  try {
    let result: Record<string, unknown> | null = null;
    await session.withTransaction(async () => {
      const provider = await Provider.findById(id).session(session);
      if (!provider) throw ApiError.notFound('Provider not found.');

      const reviewedAt = new Date();
      const approved = status === 'approved';

      provider.verificationStatus = approved
        ? VerificationStatus.APPROVED
        : VerificationStatus.REJECTED;
      provider.verificationDocuments.forEach((doc) => {
        doc.reviewedAt = reviewedAt;
        doc.isApproved = approved;
      });
      await provider.save({ session });

      const user = await User.findById(provider.user).session(session);
      if (user) {
        user.status = approved ? AccountStatus.ACTIVE : AccountStatus.PENDING;
        await user.save({ session });
      }

      result = {
        ...provider.toObject(),
        reviewNote: note ?? null,
        reviewedBy: reviewerId.toString(),
      };
    });
    return result as unknown as Record<string, unknown>;
  } finally {
    await session.endSession();
  }
}

// ---------------------------------------------------------------------------
// Commission controls
// ---------------------------------------------------------------------------

export async function setProviderCommission(
  id: string,
  rate: number | null,
): Promise<Record<string, unknown>> {
  const provider = await Provider.findById(id);
  if (!provider) throw ApiError.notFound('Provider not found.');
  provider.commissionRateOverride = rate;
  await provider.save();
  return provider.toObject() as unknown as Record<string, unknown>;
}

export async function getCommissionSettings(): Promise<{ defaultCommissionRate: number }> {
  const settings = await getPlatformSettings();
  return { defaultCommissionRate: settings.defaultCommissionRate };
}

export async function updatePlatformCommission(
  rate: number,
  adminId: mongoose.Types.ObjectId,
): Promise<{ defaultCommissionRate: number }> {
  const settings = await setPlatformCommissionRate(rate, adminId);
  return { defaultCommissionRate: settings.defaultCommissionRate };
}

// ---------------------------------------------------------------------------
// System metrics
// ---------------------------------------------------------------------------

type CountRow = { _id: string | null; count: number };

function tally(rows: CountRow[]): Record<string, number> {
  return rows.reduce<Record<string, number>>((acc, row) => {
    acc[row._id ?? 'unknown'] = row.count;
    return acc;
  }, {});
}

export interface SystemMetrics {
  users: Record<string, number>;
  providersByVerification: Record<string, number>;
  appointmentsByStatus: Record<string, number>;
  payments: {
    byStatus: Record<string, { count: number; gross: number; commission: number }>;
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
  withdrawalsByStatus: Record<string, { count: number; amount: number }>;
}

export async function getSystemMetrics(): Promise<SystemMetrics> {
  const [
    usersByRole,
    providersByVerification,
    appointmentsByStatus,
    paymentsAgg,
    walletAgg,
    withdrawalsAgg,
  ] = await Promise.all([
    User.aggregate<CountRow>([{ $group: { _id: '$role', count: { $sum: 1 } } }]),
    Provider.aggregate<CountRow>([
      { $group: { _id: '$verificationStatus', count: { $sum: 1 } } },
    ]),
    Appointment.aggregate<CountRow>([{ $group: { _id: '$status', count: { $sum: 1 } } }]),
    Appointment.aggregate<{
      _id: string;
      count: number;
      gross: number;
      commission: number;
    }>([
      {
        $group: {
          _id: '$paymentStatus',
          count: { $sum: 1 },
          gross: { $sum: '$price.amount' },
          commission: { $sum: '$commissionAmount' },
        },
      },
    ]),
    Wallet.aggregate<{
      _id: null;
      available: number;
      pending: number;
      escrow: number;
      lifetimeEarnings: number;
      lifetimeWithdrawn: number;
    }>([
      {
        $group: {
          _id: null,
          available: { $sum: '$balances.available' },
          pending: { $sum: '$balances.pending' },
          escrow: { $sum: '$balances.escrow' },
          lifetimeEarnings: { $sum: '$lifetimeEarnings' },
          lifetimeWithdrawn: { $sum: '$lifetimeWithdrawn' },
        },
      },
    ]),
    Wallet.aggregate<{ _id: string; count: number; amount: number }>([
      { $unwind: '$withdrawalRequests' },
      {
        $group: {
          _id: '$withdrawalRequests.status',
          count: { $sum: 1 },
          amount: { $sum: '$withdrawalRequests.amount' },
        },
      },
    ]),
  ]);

  const paymentsByStatus: Record<string, { count: number; gross: number; commission: number }> = {};
  let grossVolume = 0;
  let commissionEarned = 0;
  let releasedRevenue = 0;
  for (const row of paymentsAgg) {
    paymentsByStatus[row._id] = {
      count: row.count,
      gross: row.gross,
      commission: row.commission,
    };
    if (row._id === 'in_escrow' || row._id === 'released') {
      grossVolume += row.gross;
      commissionEarned += row.commission;
    }
    if (row._id === 'released') {
      releasedRevenue += row.commission;
    }
  }

  const balances = walletAgg[0] ?? {
    available: 0,
    pending: 0,
    escrow: 0,
    lifetimeEarnings: 0,
    lifetimeWithdrawn: 0,
  };

  const withdrawalsByStatus: Record<string, { count: number; amount: number }> = {};
  for (const row of withdrawalsAgg) {
    withdrawalsByStatus[row._id] = { count: row.count, amount: row.amount };
  }

  return {
    users: tally(usersByRole),
    providersByVerification: tally(providersByVerification),
    appointmentsByStatus: tally(appointmentsByStatus),
    payments: {
      byStatus: paymentsByStatus,
      grossVolume,
      commissionEarned,
      releasedRevenue,
    },
    platformBalances: {
      available: balances.available,
      pending: balances.pending,
      escrow: balances.escrow,
      lifetimeEarnings: balances.lifetimeEarnings,
      lifetimeWithdrawn: balances.lifetimeWithdrawn,
    },
    withdrawalsByStatus,
  };
}
