import { Request, Response } from 'express';
import { StopService } from '../services/stopService';
import { 
  CreateStopRequest, 
  UpdateStopRequest, 
  ReorderStopsRequest 
} from '../models/types';
import { asyncHandler } from '../middleware/errorHandler';
import { ValidationError } from '../utils/errors';

const stopService = new StopService();

/**
 * Helper function to validate required parameters
 */
function validateParam(param: string | undefined, paramName: string): string {
  if (!param) {
    throw new ValidationError(`${paramName} is required`);
  }
  return param;
}

/**
 * Add a stop to a trip
 * POST /api/trips/:shareCode/stops
 */
export const addStop = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const shareCode = validateParam(req.params.shareCode, 'shareCode');
  const data = req.body as CreateStopRequest;
  
  const stop = await stopService.addStop(shareCode, data);
  
  res.status(201).json({
    success: true,
    data: stop,
  });
});

/**
 * Update a stop
 * PUT /api/trips/:shareCode/stops/:stopId
 */
export const updateStop = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const shareCode = validateParam(req.params.shareCode, 'shareCode');
  const stopId = validateParam(req.params.stopId, 'stopId');
  const data = req.body as UpdateStopRequest;
  
  const stop = await stopService.updateStop(shareCode, stopId, data);
  
  res.json({
    success: true,
    data: stop,
  });
});

/**
 * Remove a stop from a trip
 * DELETE /api/trips/:shareCode/stops/:stopId
 */
export const removeStop = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const shareCode = validateParam(req.params.shareCode, 'shareCode');
  const stopId = validateParam(req.params.stopId, 'stopId');
  
  await stopService.removeStop(shareCode, stopId);
  
  res.status(204).send();
});

/**
 * Reorder stops in a trip
 * PUT /api/trips/:shareCode/stops/reorder
 */
export const reorderStops = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const shareCode = validateParam(req.params.shareCode, 'shareCode');
  const data = req.body as ReorderStopsRequest;
  
  const stops = await stopService.reorderStops(shareCode, data);
  
  res.json({
    success: true,
    data: stops,
  });
});

/**
 * Get all stops for a trip
 * GET /api/trips/:shareCode/stops
 */
export const getStops = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const shareCode = validateParam(req.params.shareCode, 'shareCode');
  
  const stops = await stopService.getStopsByTrip(shareCode);
  
  res.json({
    success: true,
    data: stops,
  });
});
