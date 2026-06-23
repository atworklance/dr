/**
 * Wallet routes — mounted at /api/v1/wallets.
 *
 * The revenue dashboard and withdrawal requests for the authenticated account.
 * Withdrawals are provider-only; the wallet summary is available to any
 * wallet-owning account.
 */

import { Router } from 'express';
import * as walletController from '../controllers/wallet.controller';
import { authenticate, requireRole } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';
import { UserRole } from '../../shared/enums';
import { requestWithdrawalSchema } from '../validators/payment.validators';

const router = Router();

router.use(authenticate);

router.get('/me', walletController.getMyWallet);

router.post(
  '/me/withdrawals',
  requireRole(UserRole.PROVIDER),
  validate(requestWithdrawalSchema),
  walletController.requestWithdrawal,
);

export default router;
