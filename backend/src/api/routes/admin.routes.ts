/**
 * Admin routes — mounted at /api/v1/admin.
 *
 * The Platform Control Hub: provider verification, commission controls, system
 * metrics, and the withdrawal settlement queue. Every route requires `admin`.
 */

import { Router } from 'express';
import * as adminController from '../controllers/admin.controller';
import * as walletController from '../controllers/wallet.controller';
import { authenticate, requireRole } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';
import { UserRole } from '../../shared/enums';
import { idParam } from '../validators/common.validators';
import {
  listProvidersQuerySchema,
  setPlatformCommissionSchema,
  setProviderCommissionSchema,
  setVerificationSchema,
} from '../validators/admin.validators';
import {
  processWithdrawalSchema,
  withdrawalParamsSchema,
} from '../validators/payment.validators';

const router = Router();

router.use(authenticate, requireRole(UserRole.ADMIN));

// --- System metrics --------------------------------------------------------
router.get('/metrics', adminController.getMetrics);

// --- Commission controls ---------------------------------------------------
router.get('/settings/commission', adminController.getCommissionSettings);
router.patch(
  '/settings/commission',
  validate(setPlatformCommissionSchema),
  adminController.updatePlatformCommission,
);

// --- Provider verification & per-provider commission -----------------------
router.get(
  '/providers',
  validate(listProvidersQuerySchema, 'query'),
  adminController.listProviders,
);
router.get('/providers/:id', validate(idParam, 'params'), adminController.getProvider);
router.patch(
  '/providers/:id/verification',
  validate(idParam, 'params'),
  validate(setVerificationSchema),
  adminController.setProviderVerification,
);
router.patch(
  '/providers/:id/commission',
  validate(idParam, 'params'),
  validate(setProviderCommissionSchema),
  adminController.setProviderCommission,
);

// --- Withdrawal settlement queue -------------------------------------------
router.patch(
  '/wallets/:walletId/withdrawals/:requestId',
  validate(withdrawalParamsSchema, 'params'),
  validate(processWithdrawalSchema),
  walletController.processWithdrawal,
);

export default router;
