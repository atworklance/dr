/**
 * Appointment routes — mounted at /api/v1/appointments.
 */

import { Router } from 'express';
import * as appointmentController from '../controllers/appointment.controller';
import { authenticate, requireRole } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';
import { UserRole } from '../../shared/enums';
import {
  cancelAppointmentSchema,
  createAppointmentSchema,
  listAppointmentsQuerySchema,
} from '../validators/appointment.validators';
import { idParam } from '../validators/common.validators';

const router = Router();

router.use(authenticate);

// Only clients book appointments.
router.post(
  '/',
  requireRole(UserRole.CLIENT),
  validate(createAppointmentSchema),
  appointmentController.createAppointment,
);

// Clients and providers list their own appointments.
router.get(
  '/',
  validate(listAppointmentsQuerySchema, 'query'),
  appointmentController.listMyAppointments,
);

router.get('/:id', validate(idParam, 'params'), appointmentController.getAppointment);

router.patch(
  '/:id/cancel',
  validate(idParam, 'params'),
  validate(cancelAppointmentSchema),
  appointmentController.cancelAppointment,
);

export default router;
