/**
 * Chat REST controllers — history fetch and read receipts. Real-time delivery
 * is handled by the Socket.io gateway; these endpoints back initial loads and
 * non-socket clients.
 */

import type { NextFunction, Request, Response } from 'express';
import * as chatService from '../../domain/services/chat.service';

export async function getMessages(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const limit = req.query.limit ? Number(req.query.limit) : undefined;
    const before = req.query.before ? new Date(String(req.query.before)) : undefined;
    const messages = await chatService.getHistory(req.params.id, req.user!.id, req.user!.role, {
      limit,
      before,
    });
    res.status(200).json({ success: true, data: messages });
  } catch (err) {
    next(err);
  }
}

export async function markMessagesRead(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const messageIds = Array.isArray(req.body?.messageIds)
      ? (req.body.messageIds as unknown[]).filter((m): m is string => typeof m === 'string')
      : undefined;
    const updated = await chatService.markRead(
      req.params.id,
      req.user!.id,
      req.user!.role,
      messageIds,
    );
    res.status(200).json({ success: true, data: { messageIds: updated } });
  } catch (err) {
    next(err);
  }
}
