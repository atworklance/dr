/**
 * Chat domain service.
 *
 * Persistence and authorisation for appointment-scoped messaging. Message
 * bodies are encrypted at rest (AES-256-GCM) and only ever leave this layer as
 * decrypted DTOs delivered to verified participants. `assertParticipant` is the
 * single authorisation gate reused by both the chat and video real-time layers.
 */

import { Appointment, Message, Provider, type IAppointment, type IMessage } from '../../data/models';
import { AppointmentStatus, UserRole } from '../../shared/enums';
import { ApiError } from '../../shared/apiError';

export interface MessageDTO {
  id: string;
  appointment: string;
  sender: string;
  senderRole: UserRole;
  body: string;
  deliveredAt?: Date;
  readAt?: Date;
  createdAt: Date;
}

export interface ParticipantContext {
  appointment: IAppointment;
  isClient: boolean;
  isProvider: boolean;
}

/** Statuses in which exchanging new messages is permitted. */
const CHAT_OPEN_STATUSES: AppointmentStatus[] = [
  AppointmentStatus.PENDING_PAYMENT,
  AppointmentStatus.CONFIRMED,
  AppointmentStatus.IN_PROGRESS,
  AppointmentStatus.COMPLETED,
];

export function toMessageDTO(message: IMessage): MessageDTO {
  return {
    id: message._id.toString(),
    appointment: message.appointment.toString(),
    sender: message.sender.toString(),
    senderRole: message.senderRole,
    body: message.getBody(),
    deliveredAt: message.deliveredAt,
    readAt: message.readAt,
    createdAt: message.createdAt,
  };
}

/**
 * Verify that `userId` (acting as `role`) is a participant of `appointmentId`.
 * Returns the appointment plus participant flags, or throws 403/404.
 */
export async function assertParticipant(
  appointmentId: string,
  userId: string,
  role: string,
): Promise<ParticipantContext> {
  const appointment = await Appointment.findById(appointmentId);
  if (!appointment) {
    throw ApiError.notFound('Appointment not found.');
  }

  const isClient = appointment.client.toString() === userId;
  let isProvider = false;
  if (role === UserRole.PROVIDER) {
    const provider = await Provider.findOne({ user: userId }).select('_id').lean();
    isProvider = !!provider && appointment.provider.toString() === provider._id.toString();
  }

  if (!isClient && !isProvider && role !== UserRole.ADMIN) {
    throw ApiError.forbidden('You are not a participant in this appointment.');
  }

  return { appointment, isClient, isProvider };
}

/** Persist a message from a verified sender and return its DTO. */
export async function saveMessage(
  appointmentId: string,
  senderId: string,
  senderRole: UserRole,
  body: string,
): Promise<MessageDTO> {
  const { appointment } = await assertParticipant(appointmentId, senderId, senderRole);

  if (!CHAT_OPEN_STATUSES.includes(appointment.status)) {
    throw ApiError.conflict(`Messaging is closed for an appointment in status "${appointment.status}".`);
  }

  const message = new Message({
    appointment: appointment._id,
    sender: senderId,
    senderRole,
    deliveredAt: new Date(),
  });
  message.setBody(body);
  await message.save();

  return toMessageDTO(message);
}

/** Fetch chronological history for a participant, newest page first. */
export async function getHistory(
  appointmentId: string,
  userId: string,
  role: string,
  options: { limit?: number; before?: Date } = {},
): Promise<MessageDTO[]> {
  await assertParticipant(appointmentId, userId, role);

  const limit = Math.min(Math.max(options.limit ?? 50, 1), 200);
  const filter: Record<string, unknown> = { appointment: appointmentId };
  if (options.before) filter.createdAt = { $lt: options.before };

  const messages = await Message.find(filter).sort({ createdAt: -1 }).limit(limit);
  // Return ascending (oldest -> newest) for natural rendering.
  return messages.reverse().map(toMessageDTO);
}

/** Mark the counterparty's messages as read; returns the affected message ids. */
export async function markRead(
  appointmentId: string,
  userId: string,
  role: string,
  messageIds?: string[],
): Promise<string[]> {
  await assertParticipant(appointmentId, userId, role);

  const filter: Record<string, unknown> = {
    appointment: appointmentId,
    sender: { $ne: userId }, // only the other party's messages can be marked read.
    readAt: { $exists: false },
  };
  if (messageIds && messageIds.length > 0) {
    filter._id = { $in: messageIds };
  }

  const unread = await Message.find(filter).select('_id');
  if (unread.length === 0) return [];

  const ids = unread.map((m) => m._id);
  await Message.updateMany({ _id: { $in: ids } }, { $set: { readAt: new Date() } });
  return ids.map((id) => id.toString());
}
