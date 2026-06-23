/**
 * Specialist (provider) directory routes — mounted at /api/v1/providers.
 *
 * Authenticated read-only discovery: search the approved provider directory and
 * fetch a single specialist's public profile. Provider-self availability lives
 * under /providers/me/availability (mounted separately, ahead of this router).
 */

import { Router } from 'express';
import * as providerController from '../controllers/provider.controller';
import { authenticate } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';
import { searchProvidersSchema } from '../validators/provider.validators';
import { idParam } from '../validators/common.validators';

const router = Router();

router.use(authenticate);

router.get('/', validate(searchProvidersSchema, 'query'), providerController.searchProviders);
router.get('/:id', validate(idParam, 'params'), providerController.getProviderById);

export default router;
