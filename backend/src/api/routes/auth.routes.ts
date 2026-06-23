/**
 * Authentication & registration routes — mounted at /api/v1/auth.
 */

import { Router } from 'express';
import * as authController from '../controllers/auth.controller';
import { authenticate } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';
import {
  loginSchema,
  registerClientSchema,
  registerProviderSchema,
} from '../validators/auth.validators';

const router = Router();

router.post('/register/client', validate(registerClientSchema), authController.registerClient);
router.post('/register/provider', validate(registerProviderSchema), authController.registerProvider);
router.post('/login', validate(loginSchema), authController.login);
router.get('/me', authenticate, authController.me);

export default router;
