/**
 * Admin routes — mounted at /api/v1/admin.
 *
 * Platform Control Hub operations. Currently exposes the withdrawal settlement
 * queue: approving, paying out, or rejecting provider withdrawal requests.
 * Every route requires the `admin` role.
 */

import { Router } from 'express';
import * as walletController from '../controllers/wallet.controller';
import { authenticate, requireRole } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';
import { UserRole } from '../../shared/enums';
import {
  processWithdrawalSchema,
  withdrawalParamsSchema,
} from '../validators/payment.validators';

const router = Router();

router.use(authenticate, requireRole(UserRole.ADMIN));

router.patch(
  '/wallets/:walletId/withdrawals/:requestId',
  validate(withdrawalParamsSchema, 'params'),
  validate(processWithdrawalSchema),
  walletController.processWithdrawal,
);

export default router;
