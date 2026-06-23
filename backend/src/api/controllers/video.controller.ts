/**
 * Video controllers — Agora RTC token issuance and session state transitions.
 */

import type { NextFunction, Request, Response } from 'express';
import * as videoService from '../../domain/services/video.service';

export async function getVideoToken(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const token = await videoService.issueRtcToken(req.params.id, req.user!.id, req.user!.role);
    res.status(200).json({ success: true, data: token });
  } catch (err) {
    next(err);
  }
}

export async function startVideoSession(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const appointment = await videoService.markSessionStarted(
      req.params.id,
      req.user!.id,
      req.user!.role,
    );
    res.status(200).json({ success: true, data: appointment.toJSON() });
  } catch (err) {
    next(err);
  }
}

export async function endVideoSession(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const appointment = await videoService.markSessionEnded(
      req.params.id,
      req.user!.id,
      req.user!.role,
    );
    res.status(200).json({ success: true, data: appointment.toJSON() });
  } catch (err) {
    next(err);
  }
}
