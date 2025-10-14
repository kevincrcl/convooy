import { Router } from 'express';
import { z } from 'zod';
import { validateBody, validateParams } from '../middleware/validation';
import { 
  CreateTripSchema, 
  UpdateTripSchema, 
  ShareCodeSchema 
} from '../models/types';
import {
  createTrip,
  getTripByShareCode,
  updateTrip,
  deleteTrip,
  getShareInfo,
  joinTrip,
  getTripStats,
} from '../controllers/tripController';

const router = Router();

// Parameter validation schema
const ShareCodeParamsSchema = z.object({
  shareCode: ShareCodeSchema,
});

// Trip routes
router.post(
  '/',
  validateBody(CreateTripSchema),
  createTrip
);

router.get(
  '/:shareCode',
  validateParams(ShareCodeParamsSchema),
  getTripByShareCode
);

router.put(
  '/:shareCode',
  validateParams(ShareCodeParamsSchema),
  validateBody(UpdateTripSchema),
  updateTrip
);

router.delete(
  '/:shareCode',
  validateParams(ShareCodeParamsSchema),
  deleteTrip
);

// Sharing routes
router.get(
  '/:shareCode/share',
  validateParams(ShareCodeParamsSchema),
  getShareInfo
);

router.post(
  '/join/:shareCode',
  validateParams(ShareCodeParamsSchema),
  joinTrip
);

// Statistics
router.get(
  '/:shareCode/stats',
  validateParams(ShareCodeParamsSchema),
  getTripStats
);

export default router;
