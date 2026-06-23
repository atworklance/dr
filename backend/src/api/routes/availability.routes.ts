/**
 * Provider availability routes — mounted at /api/v1/providers/me/availability.
 * Every route requires an authenticated user with the `provider` role.
 */

import { Router } from 'express';
import * as availabilityController from '../controllers/availability.controller';
import { authenticate, requireRole } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';
import { UserRole } from '../../shared/enums';
import {
  setHolidayModeSchema,
  updateWeeklyAvailabilitySchema,
  upsertAvailabilityExceptionSchema,
} from '../validators/availability.validators';

const router = Router();

router.use(authenticate, requireRole(UserRole.PROVIDER));

router.get('/', availabilityController.getMyAvailability);
router.put(
  '/weekly',
  validate(updateWeeklyAvailabilitySchema),
  availabilityController.updateWeeklyAvailability,
);
router.post(
  '/exceptions',
  validate(upsertAvailabilityExceptionSchema),
  availabilityController.upsertAvailabilityException,
);
router.patch(
  '/holiday-mode',
  validate(setHolidayModeSchema),
  availabilityController.setHolidayMode,
);

export default router;
