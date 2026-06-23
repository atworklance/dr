/**
 * Wallet ledger domain service.
 *
 * Owns every mutation of a wallet's balances and the append-only transaction
 * ledger. All amounts are integer MINOR units (cents). Each movement is applied
 * atomically and records a `balanceAfter` snapshot of the available balance for
 * a tamper-evident audit trail. Non-negativity of every bucket is enforced, so
 * an over-draw (e.g. withdrawing more than is available) is rejected rather than
 * silently producing a negative balance.
 *
 * Mutating helpers accept an optional Mongoose session so a caller (e.g. the
 * payment service) can compose wallet changes with appointment changes inside a
 * single transaction.
 */

import mongoose, { type ClientSession, type Types } from 'mongoose';
import { Wallet, type IWallet, type IWalletTransaction } from '../../data/models';
import {
  WalletTxnStatus,
  WalletTxnType,
  WithdrawalStatus,
  type SupportedCurrency,
} from '../../shared/enums';
import { ApiError } from '../../shared/apiError';
import { config } from '../../config';

/** Withdrawal states that still hold a reservation against the wallet. */
const ACTIVE_WITHDRAWAL_STATUSES: WithdrawalStatus[] = [
  WithdrawalStatus.REQUESTED,
  WithdrawalStatus.APPROVED,
  WithdrawalStatus.PROCESSING,
];

interface MovementInput {
  type: WalletTxnType;
  status?: WalletTxnStatus;
  /** Signed magnitude recorded on the ledger entry (positive inflow / negative outflow). */
  amount: number;
  /** Per-bucket balance deltas applied to the wallet. */
  deltas: { available?: number; pending?: number; escrow?: number };
  appointment?: Types.ObjectId;
  reference?: string;
  description?: string;
}

function assertInteger(value: number, label: string): void {
  if (!Number.isInteger(value)) {
    throw ApiError.badRequest(`${label} must be an integer number of minor units.`);
  }
}

/** Applies a balance movement to an in-memory wallet doc and appends a ledger entry. */
function pushMovement(wallet: IWallet, input: MovementInput): IWalletTransaction {
  const nextAvailable = wallet.balances.available + (input.deltas.available ?? 0);
  const nextPending = wallet.balances.pending + (input.deltas.pending ?? 0);
  const nextEscrow = wallet.balances.escrow + (input.deltas.escrow ?? 0);

  if (nextAvailable < 0 || nextPending < 0 || nextEscrow < 0) {
    throw ApiError.conflict('Insufficient wallet balance for this operation.');
  }

  wallet.balances.available = nextAvailable;
  wallet.balances.pending = nextPending;
  wallet.balances.escrow = nextEscrow;

  wallet.transactions.push({
    type: input.type,
    status: input.status ?? WalletTxnStatus.SETTLED,
    amount: input.amount,
    balanceAfter: nextAvailable,
    currency: wallet.currency,
    appointment: input.appointment,
    reference: input.reference,
    description: input.description,
  } as IWalletTransaction);

  return wallet.transactions[wallet.transactions.length - 1];
}

async function loadWalletByOwner(ownerUserId: string, session?: ClientSession): Promise<IWallet> {
  const query = Wallet.findOne({ owner: ownerUserId });
  if (session) query.session(session);
  const wallet = await query;
  if (!wallet) {
    throw ApiError.notFound('Wallet not found for this account.');
  }
  if (wallet.isFrozen) {
    throw ApiError.forbidden('This wallet is frozen and cannot be modified.');
  }
  return wallet;
}

function assertCurrency(wallet: IWallet, currency: SupportedCurrency): void {
  if (wallet.currency !== currency) {
    throw ApiError.badRequest(
      `Currency mismatch: wallet is ${wallet.currency} but operation is ${currency}.`,
    );
  }
}

/** Move a provider's net share into escrow when a client's payment is captured. */
export async function holdInEscrow(
  ownerUserId: string,
  amount: number,
  currency: SupportedCurrency,
  appointmentId: Types.ObjectId,
  session?: ClientSession,
  paymentReference?: string,
): Promise<IWallet> {
  assertInteger(amount, 'escrow amount');
  if (amount <= 0) throw ApiError.badRequest('Escrow amount must be positive.');
  const wallet = await loadWalletByOwner(ownerUserId, session);
  assertCurrency(wallet, currency);
  pushMovement(wallet, {
    type: WalletTxnType.ESCROW_HOLD,
    status: WalletTxnStatus.PENDING,
    amount,
    deltas: { escrow: amount },
    appointment: appointmentId,
    reference: `escrow_${appointmentId.toString()}`,
    description: paymentReference
      ? `Funds held in escrow pending completion (gateway ref: ${paymentReference}).`
      : 'Funds held in escrow pending appointment completion.',
  });
  await wallet.save({ session });
  return wallet;
}

/** Release escrowed funds to the provider's available balance on completion. */
export async function releaseEscrow(
  ownerUserId: string,
  amount: number,
  currency: SupportedCurrency,
  appointmentId: Types.ObjectId,
  session?: ClientSession,
): Promise<IWallet> {
  assertInteger(amount, 'release amount');
  if (amount <= 0) throw ApiError.badRequest('Release amount must be positive.');
  const wallet = await loadWalletByOwner(ownerUserId, session);
  assertCurrency(wallet, currency);
  pushMovement(wallet, {
    type: WalletTxnType.ESCROW_RELEASE,
    status: WalletTxnStatus.SETTLED,
    amount,
    deltas: { escrow: -amount, available: amount },
    appointment: appointmentId,
    reference: `release_${appointmentId.toString()}`,
    description: 'Escrow released to available balance on appointment completion.',
  });
  // Mark the original hold as settled.
  const hold = wallet.transactions.find(
    (t) => t.reference === `escrow_${appointmentId.toString()}`,
  );
  if (hold) hold.status = WalletTxnStatus.SETTLED;

  wallet.lifetimeEarnings += amount;
  await wallet.save({ session });
  return wallet;
}

/** Reverse an escrow hold when an escrowed appointment is cancelled / refunded. */
export async function refundEscrow(
  ownerUserId: string,
  amount: number,
  currency: SupportedCurrency,
  appointmentId: Types.ObjectId,
  session?: ClientSession,
): Promise<IWallet> {
  assertInteger(amount, 'refund amount');
  if (amount <= 0) throw ApiError.badRequest('Refund amount must be positive.');
  const wallet = await loadWalletByOwner(ownerUserId, session);
  assertCurrency(wallet, currency);
  pushMovement(wallet, {
    type: WalletTxnType.REFUND,
    status: WalletTxnStatus.SETTLED,
    amount: -amount,
    deltas: { escrow: -amount },
    appointment: appointmentId,
    reference: `refund_${appointmentId.toString()}`,
    description: 'Escrow reversed and refunded to client on cancellation.',
  });
  const hold = wallet.transactions.find(
    (t) => t.reference === `escrow_${appointmentId.toString()}`,
  );
  if (hold) hold.status = WalletTxnStatus.REVERSED;

  await wallet.save({ session });
  return wallet;
}

export interface WalletSummary {
  walletId: string;
  currency: SupportedCurrency;
  balances: { available: number; pending: number; escrow: number };
  totalBalance: number;
  lifetimeEarnings: number;
  lifetimeWithdrawn: number;
  pendingWithdrawals: number;
  recentTransactions: IWalletTransaction[];
}

export async function getWalletSummary(ownerUserId: string): Promise<WalletSummary> {
  const wallet = await Wallet.findOne({ owner: ownerUserId });
  if (!wallet) throw ApiError.notFound('Wallet not found for this account.');

  const recentTransactions = [...wallet.transactions]
    .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
    .slice(0, 20);

  const pendingWithdrawals = wallet.withdrawalRequests.filter((w) =>
    ACTIVE_WITHDRAWAL_STATUSES.includes(w.status),
  ).length;

  return {
    walletId: wallet._id.toString(),
    currency: wallet.currency,
    balances: { ...wallet.balances },
    totalBalance: wallet.totalBalance,
    lifetimeEarnings: wallet.lifetimeEarnings,
    lifetimeWithdrawn: wallet.lifetimeWithdrawn,
    pendingWithdrawals,
    recentTransactions,
  };
}

/** Provider requests a payout: reserves funds by moving available -> pending. */
export async function requestWithdrawal(
  ownerUserId: string,
  amount: number,
  payoutMethod: string,
): Promise<{ wallet: IWallet; requestId: string }> {
  assertInteger(amount, 'withdrawal amount');
  if (amount < config.minWithdrawalMinorUnits) {
    throw ApiError.unprocessable(
      `Minimum withdrawal is ${config.minWithdrawalMinorUnits} minor units.`,
    );
  }

  const session = await mongoose.startSession();
  try {
    let requestId = '';
    let saved: IWallet | null = null;
    await session.withTransaction(async () => {
      const wallet = await loadWalletByOwner(ownerUserId, session);
      if (wallet.balances.available < amount) {
        throw ApiError.unprocessable('Requested amount exceeds available balance.');
      }

      const request = wallet.withdrawalRequests.create({
        amount,
        currency: wallet.currency,
        status: WithdrawalStatus.REQUESTED,
        payoutMethod,
      });
      wallet.withdrawalRequests.push(request);
      requestId = request._id.toString();

      pushMovement(wallet, {
        type: WalletTxnType.WITHDRAWAL,
        status: WalletTxnStatus.PENDING,
        amount: -amount,
        deltas: { available: -amount, pending: amount },
        reference: `wd_${requestId}`,
        description: 'Withdrawal requested; funds reserved pending settlement.',
      });

      await wallet.save({ session });
      saved = wallet;
    });
    return { wallet: saved as unknown as IWallet, requestId };
  } finally {
    await session.endSession();
  }
}

export type WithdrawalAction = 'approve' | 'mark_paid' | 'reject';

/** Admin transitions a withdrawal request through its settlement lifecycle. */
export async function processWithdrawal(
  walletId: string,
  requestId: string,
  action: WithdrawalAction,
  options: { payoutReference?: string; rejectionReason?: string } = {},
): Promise<IWallet> {
  const session = await mongoose.startSession();
  try {
    let saved: IWallet | null = null;
    await session.withTransaction(async () => {
      const wallet = await Wallet.findById(walletId).session(session);
      if (!wallet) throw ApiError.notFound('Wallet not found.');

      const request = wallet.withdrawalRequests.id(requestId);
      if (!request) throw ApiError.notFound('Withdrawal request not found.');

      const ledgerEntry = wallet.transactions.find((t) => t.reference === `wd_${requestId}`);

      if (action === 'approve') {
        if (request.status !== WithdrawalStatus.REQUESTED) {
          throw ApiError.conflict('Only a requested withdrawal can be approved.');
        }
        request.status = WithdrawalStatus.APPROVED;
      } else if (action === 'mark_paid') {
        if (!ACTIVE_WITHDRAWAL_STATUSES.includes(request.status)) {
          throw ApiError.conflict(`A ${request.status} withdrawal cannot be marked paid.`);
        }
        // Funds leave the platform: drain the reserved pending bucket.
        pushMovement(wallet, {
          type: WalletTxnType.WITHDRAWAL,
          status: WalletTxnStatus.SETTLED,
          amount: -request.amount,
          deltas: { pending: -request.amount },
          reference: `wd_paid_${requestId}`,
          description: 'Withdrawal settled and paid out off-platform.',
        });
        if (ledgerEntry) ledgerEntry.status = WalletTxnStatus.SETTLED;
        wallet.lifetimeWithdrawn += request.amount;
        request.status = WithdrawalStatus.PAID;
        request.processedAt = new Date();
        if (options.payoutReference) request.payoutReference = options.payoutReference;
      } else {
        // reject — release the reservation back to available.
        if (request.status === WithdrawalStatus.PAID) {
          throw ApiError.conflict('A paid withdrawal cannot be rejected.');
        }
        pushMovement(wallet, {
          type: WalletTxnType.WITHDRAWAL,
          status: WalletTxnStatus.REVERSED,
          amount: request.amount,
          deltas: { pending: -request.amount, available: request.amount },
          reference: `wd_reject_${requestId}`,
          description: 'Withdrawal rejected; reserved funds returned to available balance.',
        });
        if (ledgerEntry) ledgerEntry.status = WalletTxnStatus.REVERSED;
        request.status = WithdrawalStatus.REJECTED;
        request.processedAt = new Date();
        if (options.rejectionReason) request.rejectionReason = options.rejectionReason;
      }

      await wallet.save({ session });
      saved = wallet;
    });
    return saved as unknown as IWallet;
  } finally {
    await session.endSession();
  }
}
