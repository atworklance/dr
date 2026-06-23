/**
 * Message model — persistent chat history for an appointment's live session.
 *
 * Messages are tied to an appointment and exchanged only between its two
 * participants (client and provider). Bodies are encrypted at rest with the
 * same AES-256-GCM field encryption used for client notes; the plaintext is
 * accessed via the `setBody` / `getBody` helpers and is never stored raw.
 */

import { Schema, model, Types, type Document, type Model } from 'mongoose';
import { UserRole, USER_ROLES } from '../../shared/enums';
import { encryptField, decryptField, type EncryptedPayload } from '../../shared/crypto';

const EncryptedPayloadSchema = new Schema<EncryptedPayload>(
  {
    iv: { type: String, required: true },
    content: { type: String, required: true },
    authTag: { type: String, required: true },
  },
  { _id: false },
);

export interface IMessage extends Document<Types.ObjectId> {
  appointment: Types.ObjectId;
  sender: Types.ObjectId;
  senderRole: UserRole;
  encryptedBody: EncryptedPayload;
  deliveredAt?: Date;
  readAt?: Date;
  createdAt: Date;
  updatedAt: Date;
  setBody(plaintext: string): void;
  getBody(): string;
}

export type IMessageModel = Model<IMessage>;

const MessageSchema = new Schema<IMessage, IMessageModel>(
  {
    appointment: {
      type: Schema.Types.ObjectId,
      ref: 'Appointment',
      required: [true, 'A message must belong to an appointment.'],
      index: true,
    },
    sender: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'A message must have a sender.'],
    },
    senderRole: {
      type: String,
      enum: { values: USER_ROLES, message: '{VALUE} is not a valid sender role.' },
      required: true,
    },
    encryptedBody: { type: EncryptedPayloadSchema, required: true },
    deliveredAt: { type: Date },
    readAt: { type: Date },
  },
  {
    timestamps: true,
    strict: 'throw',
    minimize: false,
    versionKey: false,
    toJSON: {
      virtuals: true,
      transform(_doc, ret: Record<string, unknown>) {
        // Never expose the ciphertext envelope over the wire.
        delete ret.encryptedBody;
        return ret;
      },
    },
    toObject: { virtuals: true },
  },
);

MessageSchema.methods.setBody = function (this: IMessage, plaintext: string): void {
  if (!plaintext || plaintext.trim().length === 0) {
    throw new Error('Message body cannot be empty.');
  }
  if (plaintext.length > 4000) {
    throw new Error('Message body cannot exceed 4000 characters.');
  }
  this.encryptedBody = encryptField(plaintext);
};

MessageSchema.methods.getBody = function (this: IMessage): string {
  return decryptField(this.encryptedBody);
};

// Conversation timeline: fetch an appointment's messages in chronological order.
MessageSchema.index({ appointment: 1, createdAt: 1 }, { name: 'idx_message_appointment_time' });
// Unread-receipt scans per appointment.
MessageSchema.index(
  { appointment: 1, readAt: 1 },
  { name: 'idx_message_unread', partialFilterExpression: { readAt: { $exists: false } } },
);

export const Message = model<IMessage, IMessageModel>('Message', MessageSchema);
export default Message;
