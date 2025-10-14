import { Router } from 'express';
import { z } from 'zod';
import { validateBody, validateParams } from '../middleware/validation';
import { 
  CreateStopSchema, 
  UpdateStopSchema, 
  ReorderStopsSchema,
  ShareCodeSchema 
} from '../models/types';
import {
  addStop,
  updateStop,
  removeStop,
  reorderStops,
  getStops,
} from '../controllers/stopController';

const router = Router();

// Parameter validation schemas
const ShareCodeParamsSchema = z.object({
  shareCode: ShareCodeSchema,
});

const StopParamsSchema = z.object({
  shareCode: ShareCodeSchema,
  stopId: z.string().min(1, 'Stop ID is required'),
});

// Stop routes
router.post(
  '/:shareCode/stops',
  validateParams(ShareCodeParamsSchema),
  validateBody(CreateStopSchema),
  addStop
);

router.get(
  '/:shareCode/stops',
  validateParams(ShareCodeParamsSchema),
  getStops
);

router.put(
  '/:shareCode/stops/:stopId',
  validateParams(StopParamsSchema),
  validateBody(UpdateStopSchema),
  updateStop
);

router.delete(
  '/:shareCode/stops/:stopId',
  validateParams(StopParamsSchema),
  removeStop
);

router.put(
  '/:shareCode/stops/reorder',
  validateParams(ShareCodeParamsSchema),
  validateBody(ReorderStopsSchema),
  reorderStops
);

export default router;
