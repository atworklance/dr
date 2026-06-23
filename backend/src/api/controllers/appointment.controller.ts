/**
 * Appointment controllers — HTTP adapters over the booking domain service.
 */

import type { NextFunction, Request, Response } from 'express';
import * as appointmentService from '../../domain/services/appointment.service';
import { ApiError } from '../../shared/apiError';
import type {
  CancelAppointmentInput,
  CreateAppointmentInput,
  ListAppointmentsQuery,
} from '../validators/appointment.validators';

export async function createAppointment(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const appointment = await appointmentService.createAppointment(
      req.user!.id,
      req.body as CreateAppointmentInput,
    );
    res.status(201).json({ success: true, data: appointment.toJSON() });
  } catch (err) {
    next(err);
  }
}

export async function listMyAppointments(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const role = req.user!.role === 'provider' ? 'provider' : 'client';
    const result = await appointmentService.listAppointmentsForUser(
      req.user!.id,
      role,
      req.query as unknown as ListAppointmentsQuery,
    );
    res.status(200).json({
      success: true,
      data: result.items.map((a) => a.toJSON()),
      meta: { total: result.total, page: result.page, limit: result.limit },
    });
  } catch (err) {
    next(err);
  }
}

export async function getAppointment(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { appointment, notes } = await appointmentService.getAppointmentForParticipant(
      req.params.id,
      req.user!.id,
      req.user!.role,
    );
    const data = appointment.toJSON() as Record<string, unknown>;
    delete data.encryptedNotes; // never expose the ciphertext envelope.
    data.notes = notes; // decrypted plaintext for authorised participants only.
    res.status(200).json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

export async function cancelAppointment(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.params.id) {
      throw ApiError.badRequest('Appointment id is required.');
    }
    const { reason } = req.body as CancelAppointmentInput;
    const appointment = await appointmentService.cancelAppointment(
      req.params.id,
      req.user!.id,
      req.user!.role,
      reason,
    );
    res.status(200).json({ success: true, data: appointment.toJSON() });
  } catch (err) {
    next(err);
  }
}
