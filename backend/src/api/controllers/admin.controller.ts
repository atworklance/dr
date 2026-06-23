/**
 * Admin controllers — HTTP adapters over the admin domain service.
 */

import { Types } from 'mongoose';
import type { NextFunction, Request, Response } from 'express';
import * as adminService from '../../domain/services/admin.service';
import type {
  ListProvidersQueryInput,
  SetPlatformCommissionInput,
  SetProviderCommissionInput,
  SetVerificationInput,
} from '../validators/admin.validators';

export async function listProviders(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const result = await adminService.listProviders(
      req.query as unknown as ListProvidersQueryInput,
    );
    res.status(200).json({
      success: true,
      data: result.items,
      meta: { total: result.total, page: result.page, limit: result.limit },
    });
  } catch (err) {
    next(err);
  }
}

export async function getProvider(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const provider = await adminService.getProviderDetail(req.params.id);
    res.status(200).json({ success: true, data: provider });
  } catch (err) {
    next(err);
  }
}

export async function setProviderVerification(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { status, note } = req.body as SetVerificationInput;
    const provider = await adminService.setProviderVerification(
      req.params.id,
      status,
      new Types.ObjectId(req.user!.id),
      note,
    );
    res.status(200).json({ success: true, data: provider });
  } catch (err) {
    next(err);
  }
}

export async function setProviderCommission(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { rate } = req.body as SetProviderCommissionInput;
    const provider = await adminService.setProviderCommission(req.params.id, rate);
    res.status(200).json({ success: true, data: provider });
  } catch (err) {
    next(err);
  }
}

export async function getCommissionSettings(
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const settings = await adminService.getCommissionSettings();
    res.status(200).json({ success: true, data: settings });
  } catch (err) {
    next(err);
  }
}

export async function updatePlatformCommission(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { rate } = req.body as SetPlatformCommissionInput;
    const settings = await adminService.updatePlatformCommission(
      rate,
      new Types.ObjectId(req.user!.id),
    );
    res.status(200).json({ success: true, data: settings });
  } catch (err) {
    next(err);
  }
}

export async function getMetrics(
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const metrics = await adminService.getSystemMetrics();
    res.status(200).json({ success: true, data: metrics });
  } catch (err) {
    next(err);
  }
}
