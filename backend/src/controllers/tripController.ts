import { Request, Response } from 'express';
import { TripService } from '../services/tripService';
import { 
  CreateTripRequest, 
  UpdateTripRequest, 
  ShareResponse 
} from '../models/types';
import { asyncHandler } from '../middleware/errorHandler';
import { formatShareCode } from '../utils/shareCode';

const tripService = new TripService();

/**
 * Create a new trip
 * POST /api/trips
 */
export const createTrip = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const data = req.body as CreateTripRequest;
  const trip = await tripService.createTrip(data);
  
  res.status(201).json({
    success: true,
    data: trip,
  });
});

/**
 * Get trip by share code
 * GET /api/trips/:shareCode
 */
export const getTripByShareCode = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const { shareCode } = req.params;
  const trip = await tripService.getTripByShareCode(shareCode);
  
  res.json({
    success: true,
    data: trip,
  });
});

/**
 * Update trip details
 * PUT /api/trips/:shareCode
 */
export const updateTrip = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const { shareCode } = req.params;
  const data = req.body as UpdateTripRequest;
  
  const trip = await tripService.updateTrip(shareCode, data);
  
  res.json({
    success: true,
    data: trip,
  });
});

/**
 * Delete trip
 * DELETE /api/trips/:shareCode
 */
export const deleteTrip = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const { shareCode } = req.params;
  
  await tripService.deleteTrip(shareCode);
  
  res.status(204).send();
});

/**
 * Get shareable information for a trip
 * GET /api/trips/:shareCode/share
 */
export const getShareInfo = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const { shareCode } = req.params;
  
  // Verify trip exists
  const exists = await tripService.tripExists(shareCode);
  if (!exists) {
    res.status(404).json({
      success: false,
      error: 'Trip not found',
    });
    return;
  }

  const baseUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
  const shareResponse: ShareResponse = {
    shareCode: formatShareCode(shareCode),
    shareUrl: `${baseUrl}/trip/${shareCode}`,
    // QR code URL could be generated here or by a separate service
    qrCodeUrl: `${baseUrl}/api/trips/${shareCode}/qr`,
  };
  
  res.json({
    success: true,
    data: shareResponse,
  });
});

/**
 * Join a trip (same as getting trip info, but could track analytics)
 * POST /api/trips/join/:shareCode
 */
export const joinTrip = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const { shareCode } = req.params;
  const trip = await tripService.getTripByShareCode(shareCode);
  
  // Here you could track join events, participant counts, etc.
  
  res.json({
    success: true,
    data: trip,
    message: 'Successfully joined trip',
  });
});

/**
 * Get trip statistics
 * GET /api/trips/:shareCode/stats
 */
export const getTripStats = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const { shareCode } = req.params;
  const stats = await tripService.getTripStats(shareCode);
  
  res.json({
    success: true,
    data: stats,
  });
});
