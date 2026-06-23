/**
 * Video communication service.
 *
 * Issues short-lived Agora RTC access tokens for an appointment's video channel
 * and manages the live session's connection state (start/end), flipping the
 * appointment into IN_PROGRESS on first connect. Tokens are bound to the
 * appointment's pre-provisioned channel and to the requesting user's account,
 * so a token is only useful inside the intended call.
 */

import { RtcRole, RtcTokenBuilder } from 'agora-token';
import type { IAppointment } from '../../data/models';
import { AppointmentStatus } from '../../shared/enums';
import { ApiError } from '../../shared/apiError';
import { config, isAgoraConfigured } from '../../config';
import { assertParticipant } from './chat.service';

export interface RtcTokenResult {
  appId: string;
  channel: string;
  /** Agora user account the token is bound to (the platform user id). */
  account: string;
  token: string;
  role: 'publisher';
  /** Unix epoch seconds at which the token/privilege expires. */
  expiresAt: number;
}

/** Statuses in which a live video session may be established. */
const VIDEO_OPEN_STATUSES: AppointmentStatus[] = [
  AppointmentStatus.CONFIRMED,
  AppointmentStatus.IN_PROGRESS,
];

function requireChannel(appointment: IAppointment): string {
  const channel = appointment.session.videoChannelName;
  if (!channel) {
    throw ApiError.conflict('No video channel is provisioned for this appointment.');
  }
  return channel;
}

/** Build an Agora RTC publisher token for a verified participant. */
export async function issueRtcToken(
  appointmentId: string,
  userId: string,
  role: string,
): Promise<RtcTokenResult> {
  if (!isAgoraConfigured()) {
    throw new ApiError(503, 'Video service is not configured (missing Agora credentials).');
  }

  const { appointment } = await assertParticipant(appointmentId, userId, role);
  if (appointment.consultationMode !== 'online') {
    throw ApiError.conflict('Video tokens are only available for online consultations.');
  }
  if (!VIDEO_OPEN_STATUSES.includes(appointment.status)) {
    throw ApiError.conflict(
      `A video session cannot start for an appointment in status "${appointment.status}".`,
    );
  }

  const channel = requireChannel(appointment);
  const ttl = config.agora.tokenTtlSeconds;

  const token = RtcTokenBuilder.buildTokenWithUserAccount(
    config.agora.appId,
    config.agora.appCertificate,
    channel,
    userId, // account-based: stable across reconnects, no uid collisions.
    RtcRole.PUBLISHER,
    ttl,
    ttl,
  );

  return {
    appId: config.agora.appId,
    channel,
    account: userId,
    token,
    role: 'publisher',
    expiresAt: Math.floor(Date.now() / 1000) + ttl,
  };
}

/** Record that a participant has joined the live session. */
export async function markSessionStarted(
  appointmentId: string,
  userId: string,
  role: string,
): Promise<IAppointment> {
  const { appointment } = await assertParticipant(appointmentId, userId, role);
  if (!VIDEO_OPEN_STATUSES.includes(appointment.status)) {
    throw ApiError.conflict(
      `A video session cannot start for an appointment in status "${appointment.status}".`,
    );
  }

  if (!appointment.session.startedAt) {
    appointment.session.startedAt = new Date();
  }
  if (appointment.status === AppointmentStatus.CONFIRMED) {
    appointment.status = AppointmentStatus.IN_PROGRESS;
  }
  await appointment.save();
  return appointment;
}

/** Record that the live session has ended (does not settle payment). */
export async function markSessionEnded(
  appointmentId: string,
  userId: string,
  role: string,
): Promise<IAppointment> {
  const { appointment } = await assertParticipant(appointmentId, userId, role);
  appointment.session.endedAt = new Date();
  await appointment.save();
  return appointment;
}
