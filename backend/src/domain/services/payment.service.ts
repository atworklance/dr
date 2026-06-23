/**
 * Payment & escrow orchestration service.
 *
 * Bridges the appointment lifecycle and the wallet ledger:
 *   - capturePayment:    client pays -> provider net moves into escrow,
 *                        appointment becomes CONFIRMED / IN_ESCROW.
 *   - completeAppointment: provider completes -> escrow released to available,
 *                        appointment becomes COMPLETED / RELEASED.
 *   - refundEscrowedAppointment: cancellation of an escrowed appointment ->
 *                        escrow reversed, appointment becomes REFUNDED.
 *
 * Every flow runs inside a MongoDB transaction so the appointment state and the
 * wallet balances move together or not at all. (Requires a replica set / Atlas.)
 */

import mongoose, { type ClientSession } from 'mongoose';
import { Appointment, Provider, type IAppointment } from '../../data/models';
import {
  AppointmentStatus,
  PaymentStatus,
  VerificationStatus,
} from '../../shared/enums';
import { ApiError } from '../../shared/apiError';
import * as walletService from './wallet.service';

/** Provider's net share = gross price minus the platform commission. */
function netProviderShare(appointment: IAppointment): number {
  return appointment.price.amount - appointment.commissionAmount;
}

async function resolveProviderUser(
  providerId: mongoose.Types.ObjectId,
  session: ClientSession,
): Promise<{ providerUserId: string }> {
  const provider = await Provider.findById(providerId).select('user').session(session).lean();
  if (!provider) {
    throw ApiError.notFound('Provider profile not found for this appointment.');
  }
  return { providerUserId: provider.user.toString() };
}

export interface CapturePaymentInput {
  paymentReference: string;
}

/**
 * Capture a client's payment for a pending appointment and place the provider's
 * net share into escrow. Simulates a successful external gateway capture keyed
 * by `paymentReference`; the funds movement is the platform-side bookkeeping.
 */
export async function capturePayment(
  appointmentId: string,
  clientId: string,
  input: CapturePaymentInput,
): Promise<IAppointment> {
  const session = await mongoose.startSession();
  try {
    let result: IAppointment | null = null;
    await session.withTransaction(async () => {
      const appointment = await Appointment.findById(appointmentId).session(session);
      if (!appointment) throw ApiError.notFound('Appointment not found.');
      if (appointment.client.toString() !== clientId) {
        throw ApiError.forbidden('Only the booking client can pay for this appointment.');
      }
      if (
        appointment.status !== AppointmentStatus.PENDING_PAYMENT ||
        appointment.paymentStatus !== PaymentStatus.UNPAID
      ) {
        throw ApiError.conflict('This appointment is not awaiting payment.');
      }

      const { providerUserId } = await resolveProviderUser(appointment.provider, session);
      const net = netProviderShare(appointment);
      if (net > 0) {
        await walletService.holdInEscrow(
          providerUserId,
          net,
          appointment.price.currency,
          appointment._id,
          session,
          input.paymentReference,
        );
      }

      appointment.status = AppointmentStatus.CONFIRMED;
      appointment.paymentStatus = PaymentStatus.IN_ESCROW;
      await appointment.save({ session });
      result = appointment;
    });
    return result as unknown as IAppointment;
  } finally {
    await session.endSession();
  }
}

/**
 * Provider marks an in-escrow appointment complete: release the net share from
 * escrow to the provider's available balance and finalise both records.
 */
export async function completeAppointment(
  appointmentId: string,
  providerUserId: string,
): Promise<IAppointment> {
  const session = await mongoose.startSession();
  try {
    let result: IAppointment | null = null;
    await session.withTransaction(async () => {
      const appointment = await Appointment.findById(appointmentId).session(session);
      if (!appointment) throw ApiError.notFound('Appointment not found.');

      const provider = await Provider.findById(appointment.provider).session(session);
      if (!provider) throw ApiError.notFound('Provider profile not found.');
      if (provider.user.toString() !== providerUserId) {
        throw ApiError.forbidden('Only the owning provider can complete this appointment.');
      }
      if (provider.verificationStatus !== VerificationStatus.APPROVED) {
        throw ApiError.forbidden('Provider is not approved.');
      }
      const completable: AppointmentStatus[] = [
        AppointmentStatus.CONFIRMED,
        AppointmentStatus.IN_PROGRESS,
      ];
      if (
        !completable.includes(appointment.status) ||
        appointment.paymentStatus !== PaymentStatus.IN_ESCROW
      ) {
        throw ApiError.conflict('Only a confirmed, escrowed appointment can be completed.');
      }

      const net = netProviderShare(appointment);
      if (net > 0) {
        await walletService.releaseEscrow(
          provider.user.toString(),
          net,
          appointment.price.currency,
          appointment._id,
          session,
        );
      }

      appointment.status = AppointmentStatus.COMPLETED;
      appointment.paymentStatus = PaymentStatus.RELEASED;
      appointment.session.endedAt = appointment.session.endedAt ?? new Date();
      await appointment.save({ session });

      provider.totalCompletedAppointments += 1;
      await provider.save({ session });

      result = appointment;
    });
    return result as unknown as IAppointment;
  } finally {
    await session.endSession();
  }
}

/**
 * Reverse the escrow for an appointment that is being cancelled while funds are
 * still held. Designed to be called from within an existing cancellation
 * transaction (it mutates and saves the passed appointment on the same session).
 */
export async function refundEscrowedAppointment(
  appointment: IAppointment,
  session: ClientSession,
): Promise<void> {
  if (appointment.paymentStatus !== PaymentStatus.IN_ESCROW) {
    return; // nothing held — nothing to refund.
  }
  const { providerUserId } = await resolveProviderUser(appointment.provider, session);
  const net = netProviderShare(appointment);
  if (net > 0) {
    await walletService.refundEscrow(
      providerUserId,
      net,
      appointment.price.currency,
      appointment._id,
      session,
    );
  }
  appointment.paymentStatus = PaymentStatus.REFUNDED;
}
