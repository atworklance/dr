/**
 * Wallet controllers — revenue dashboard, withdrawal requests, and the admin
 * settlement queue.
 */

import type { NextFunction, Request, Response } from 'express';
import * as walletService from '../../domain/services/wallet.service';
import type {
  ProcessWithdrawalRequest,
  RequestWithdrawalRequest,
} from '../validators/payment.validators';

export async function getMyWallet(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const summary = await walletService.getWalletSummary(req.user!.id);
    res.status(200).json({ success: true, data: summary });
  } catch (err) {
    next(err);
  }
}

export async function requestWithdrawal(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { amount, payoutMethod } = req.body as RequestWithdrawalRequest;
    const { requestId } = await walletService.requestWithdrawal(
      req.user!.id,
      amount,
      payoutMethod,
    );
    const summary = await walletService.getWalletSummary(req.user!.id);
    res.status(201).json({ success: true, data: { requestId, wallet: summary } });
  } catch (err) {
    next(err);
  }
}

export async function processWithdrawal(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { action, payoutReference, rejectionReason } = req.body as ProcessWithdrawalRequest;
    const wallet = await walletService.processWithdrawal(
      req.params.walletId,
      req.params.requestId,
      action,
      { payoutReference, rejectionReason },
    );
    res.status(200).json({ success: true, data: wallet.toJSON() });
  } catch (err) {
    next(err);
  }
}
