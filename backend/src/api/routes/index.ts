/**
 * API v1 router aggregation.
 */

import { Router } from 'express';
import authRoutes from './auth.routes';
import availabilityRoutes from './availability.routes';
import providerRoutes from './provider.routes';
import appointmentRoutes from './appointment.routes';
import walletRoutes from './wallet.routes';
import adminRoutes from './admin.routes';

const router = Router();

router.get('/health', (_req, res) => {
  res.status(200).json({ success: true, data: { status: 'ok', timestamp: new Date().toISOString() } });
});

router.use('/auth', authRoutes);
// Mount the more specific provider-self route before the generic directory.
router.use('/providers/me/availability', availabilityRoutes);
router.use('/providers', providerRoutes);
router.use('/appointments', appointmentRoutes);
router.use('/wallets', walletRoutes);
router.use('/admin', adminRoutes);

export default router;
