/**
 * Auth controllers — thin HTTP adapters over the auth domain service.
 * Every handler wraps its logic in try/catch and forwards failures to the
 * central error middleware via `next(err)`.
 */

import type { NextFunction, Request, Response } from 'express';
import * as authService from '../../domain/services/auth.service';
import { User } from '../../data/models';
import { ApiError } from '../../shared/apiError';
import type {
  LoginInput,
  RegisterClientInput,
  RegisterProviderInput,
} from '../validators/auth.validators';

export async function registerClient(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const result = await authService.registerClient(req.body as RegisterClientInput);
    res.status(201).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

export async function registerProvider(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const result = await authService.registerProvider(req.body as RegisterProviderInput);
    res.status(201).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

export async function login(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { email, password } = req.body as LoginInput;
    const result = await authService.login(email, password);
    res.status(200).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

export async function me(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.user) {
      throw ApiError.unauthorized();
    }
    const user = await User.findById(req.user.id);
    if (!user) {
      throw ApiError.notFound('User not found.');
    }
    res.status(200).json({ success: true, data: user.toJSON() });
  } catch (err) {
    next(err);
  }
}
