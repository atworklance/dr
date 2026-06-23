/**
 * Specialist (provider) directory controllers — HTTP adapters over the provider
 * search domain service.
 */

import type { NextFunction, Request, Response } from 'express';
import * as providerService from '../../domain/services/provider.service';
import type { SearchProvidersQuery } from '../validators/provider.validators';

export async function searchProviders(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const result = await providerService.searchProviders(
      req.query as unknown as SearchProvidersQuery,
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

export async function getProviderById(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const provider = await providerService.getProviderById(req.params.id);
    res.status(200).json({ success: true, data: provider });
  } catch (err) {
    next(err);
  }
}
