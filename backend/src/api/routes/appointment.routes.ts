/**
 * Appointment routes — mounted at /api/v1/appointments.
 *
 * Covers the booking lifecycle plus the payment, completion, real-time chat
 * history, and video session sub-resources that hang off a single appointment.
 */

import { Router } from 'express';
import * as appointmentController from '../controllers/appointment.controller';
import * as paymentController from '../controllers/payment.controller';
import * as chatController from '../controllers/chat.controller';
import * as videoController from '../controllers/video.controller';
import { authenticate, requireRole } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';
import { UserRole } from '../../shared/enums';
import {
  cancelAppointmentSchema,
  createAppointmentSchema,
  listAppointmentsQuerySchema,
} from '../validators/appointment.validators';
import { capturePaymentSchema } from '../validators/payment.validators';
import { idParam } from '../validators/common.validators';

const router = Router();

router.use(authenticate);

// --- booking lifecycle -----------------------------------------------------
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

// --- payment & settlement --------------------------------------------------
// Client captures payment -> provider net moves into escrow.
router.post(
  '/:id/pay',
  requireRole(UserRole.CLIENT),
  validate(idParam, 'params'),
  validate(capturePaymentSchema),
  paymentController.payForAppointment,
);

// Provider completes the appointment -> escrow released to available balance.
router.post(
  '/:id/complete',
  requireRole(UserRole.PROVIDER),
  validate(idParam, 'params'),
  paymentController.completeAppointment,
);

// --- real-time chat history (participants only) ----------------------------
router.get('/:id/messages', validate(idParam, 'params'), chatController.getMessages);
router.patch('/:id/messages/read', validate(idParam, 'params'), chatController.markMessagesRead);

// --- live video session ----------------------------------------------------
router.post('/:id/video/token', validate(idParam, 'params'), videoController.getVideoToken);
router.post('/:id/video/start', validate(idParam, 'params'), videoController.startVideoSession);
router.post('/:id/video/end', validate(idParam, 'params'), videoController.endVideoSession);

export default router;
