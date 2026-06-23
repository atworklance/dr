/**
 * Payment controllers — capture (pay) and completion (escrow release).
 */

import type { NextFunction, Request, Response } from 'express';
import * as paymentService from '../../domain/services/payment.service';
import type { CapturePaymentRequest } from '../validators/payment.validators';

export async function payForAppointment(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { paymentReference } = req.body as CapturePaymentRequest;
    const appointment = await paymentService.capturePayment(req.params.id, req.user!.id, {
      paymentReference,
    });
    res.status(200).json({ success: true, data: appointment.toJSON() });
  } catch (err) {
    next(err);
  }
}

export async function completeAppointment(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const appointment = await paymentService.completeAppointment(req.params.id, req.user!.id);
    res.status(200).json({ success: true, data: appointment.toJSON() });
  } catch (err) {
    next(err);
  }
}
