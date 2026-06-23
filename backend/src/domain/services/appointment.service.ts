/**
 * Appointment booking domain service — the secure, double-booking-safe pipeline.
 *
 * Booking flow:
 *   1. Load + gate the provider (must exist, be APPROVED, not in Holiday Mode).
 *   2. Validate the requested window against the availability matrix and lead time.
 *   3. Price the session and compute the platform commission.
 *   4. Persist with status PENDING_PAYMENT. The Appointment model's partial
 *      unique index `uniq_provider_live_slot` guarantees that two concurrent
 *      requests for the same provider/slot cannot both succeed — the loser hits
 *      a duplicate-key error which we translate into a 409 Conflict.
 *
 * The DB index is the authority on race conditions; the pre-checks merely give
 * fast, friendly rejections for the common (uncontended) case.
 */

import mongoose from 'mongoose';
import { config } from '../../config';
import { Appointment, Provider, type IAppointment } from '../../data/models';
import {
  AppointmentStatus,
  PaymentStatus,
  VerificationStatus,
  type ConsultationMode,
} from '../../shared/enums';
import { ApiError } from '../../shared/apiError';
import { isSlotBookable } from './availability.service';
import type {
  CreateAppointmentInput,
  ListAppointmentsQuery,
} from '../../api/validators/appointment.validators';

interface MongoServerError extends Error {
  code?: number;
}

export async function createAppointment(
  clientId: string,
  input: CreateAppointmentInput,
): Promise<IAppointment> {
  const provider = await Provider.findById(input.providerId);
  if (!provider) {
    throw ApiError.notFound('Provider not found.');
  }
  if (provider.verificationStatus !== VerificationStatus.APPROVED) {
    throw ApiError.forbidden('This provider is not yet approved for bookings.');
  }
  if (provider.user.toString() === clientId) {
    throw ApiError.badRequest('You cannot book an appointment with yourself.');
  }

  const mode = input.consultationMode as ConsultationMode;

  // Booking lead time guard.
  const leadMs = provider.bookingLeadTimeMinutes * 60_000;
  if (input.start.getTime() < Date.now() + leadMs) {
    throw ApiError.unprocessable(
      `Appointments must be booked at least ${provider.bookingLeadTimeMinutes} minutes in advance.`,
    );
  }

  // Schedule eligibility against the availability matrix.
  const decision = isSlotBookable(provider, input.start, input.end, mode);
  if (!decision.ok) {
    throw ApiError.unprocessable(decision.reason ?? 'Requested slot is unavailable.');
  }

  const durationMinutes = Math.round((input.end.getTime() - input.start.getTime()) / 60000);
  const amount = mode === 'online' ? provider.pricing.onlineFee : provider.pricing.clinicFee;
  const rate = provider.commissionRateOverride ?? config.defaultCommissionRate;
  const commissionAmount = Math.round(amount * rate);

  const appointment = new Appointment({
    client: new mongoose.Types.ObjectId(clientId),
    provider: provider._id,
    consultationMode: mode,
    timeWindow: { start: input.start, end: input.end },
    durationMinutes,
    status: AppointmentStatus.PENDING_PAYMENT,
    paymentStatus: PaymentStatus.UNPAID,
    price: { amount, currency: provider.pricing.currency },
    commissionAmount,
  });

  // Pre-provision deterministic real-time session identifiers.
  appointment.session = {
    chatRoomId: `chat_${appointment._id.toString()}`,
    videoChannelName: `vch_${appointment._id.toString()}`,
    videoProvider: 'agora',
  };

  if (input.notes) {
    appointment.setNotes(input.notes); // AES-256-GCM encrypt at rest.
  }

  try {
    await appointment.save();
    return appointment;
  } catch (err) {
    if ((err as MongoServerError)?.code === 11000) {
      // The partial unique index rejected a colliding live slot.
      throw ApiError.conflict('That time slot has just been booked. Please choose another.');
    }
    throw err;
  }
}

export async function listAppointmentsForUser(
  userId: string,
  role: 'client' | 'provider',
  query: ListAppointmentsQuery,
): Promise<{ items: IAppointment[]; total: number; page: number; limit: number }> {
  const filter: mongoose.FilterQuery<IAppointment> = {};

  if (role === 'client') {
    filter.client = new mongoose.Types.ObjectId(userId);
  } else {
    const provider = await Provider.findOne({ user: userId }).select('_id').lean();
    if (!provider) {
      throw ApiError.notFound('Provider profile not found.');
    }
    filter.provider = provider._id;
  }

  if (query.status) filter.status = query.status;
  if (query.from || query.to) {
    filter['timeWindow.start'] = {};
    if (query.from) (filter['timeWindow.start'] as Record<string, Date>).$gte = query.from;
    if (query.to) (filter['timeWindow.start'] as Record<string, Date>).$lte = query.to;
  }

  const skip = (query.page - 1) * query.limit;
  const [items, total] = await Promise.all([
    Appointment.find(filter).sort({ 'timeWindow.start': -1 }).skip(skip).limit(query.limit),
    Appointment.countDocuments(filter),
  ]);

  return { items, total, page: query.page, limit: query.limit };
}

export async function getAppointmentForParticipant(
  appointmentId: string,
  userId: string,
  role: string,
): Promise<{ appointment: IAppointment; notes: string | null }> {
  // Notes are select:false; request them explicitly for authorised participants.
  const appointment = await Appointment.findById(appointmentId).select('+encryptedNotes');
  if (!appointment) {
    throw ApiError.notFound('Appointment not found.');
  }

  const isClient = appointment.client.toString() === userId;
  let isProvider = false;
  if (role === 'provider') {
    const provider = await Provider.findOne({ user: userId }).select('_id').lean();
    isProvider = !!provider && appointment.provider.toString() === provider._id.toString();
  }

  if (!isClient && !isProvider && role !== 'admin') {
    throw ApiError.forbidden('You are not a participant in this appointment.');
  }

  return { appointment, notes: appointment.getNotes() };
}

export async function cancelAppointment(
  appointmentId: string,
  userId: string,
  role: string,
  reason?: string,
): Promise<IAppointment> {
  const appointment = await Appointment.findById(appointmentId);
  if (!appointment) {
    throw ApiError.notFound('Appointment not found.');
  }

  const isClient = appointment.client.toString() === userId;
  let isProvider = false;
  if (role === 'provider') {
    const provider = await Provider.findOne({ user: userId }).select('_id').lean();
    isProvider = !!provider && appointment.provider.toString() === provider._id.toString();
  }
  if (!isClient && !isProvider && role !== 'admin') {
    throw ApiError.forbidden('You are not a participant in this appointment.');
  }

  const cancellable: AppointmentStatus[] = [
    AppointmentStatus.PENDING_PAYMENT,
    AppointmentStatus.CONFIRMED,
  ];
  if (!cancellable.includes(appointment.status)) {
    throw ApiError.conflict(`An appointment in status "${appointment.status}" cannot be cancelled.`);
  }

  appointment.status = isClient
    ? AppointmentStatus.CANCELLED_BY_CLIENT
    : AppointmentStatus.CANCELLED_BY_PROVIDER;
  appointment.cancelledBy = new mongoose.Types.ObjectId(userId);
  if (reason) appointment.cancellationReason = reason;

  await appointment.save();
  return appointment;
}
