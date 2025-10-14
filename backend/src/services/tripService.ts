import { prisma } from './database';
import { generateShareCode } from '../utils/shareCode';
import { NotFoundError, ConflictError, ValidationError } from '../utils/errors';
import { getWebSocketService } from './websocketService';
import { 
  CreateTripRequest, 
  UpdateTripRequest, 
  TripResponse, 
  StopResponse,
  Location 
} from '../models/types';

export class TripService {
  /**
   * Create a new trip with destination
   */
  async createTrip(data: CreateTripRequest): Promise<TripResponse> {
    // Generate unique share code
    let shareCode: string;
    let attempts = 0;
    const maxAttempts = 10;

    do {
      shareCode = generateShareCode();
      attempts++;
      
      const existing = await prisma.trip.findUnique({
        where: { shareCode }
      });
      
      if (!existing) break;
      
      if (attempts >= maxAttempts) {
        throw new ConflictError('Unable to generate unique share code. Please try again.');
      }
    } while (attempts < maxAttempts);

    const trip = await prisma.trip.create({
      data: {
        shareCode,
        name: data.name,
        destination: data.destination,
      },
      include: {
        stops: {
          orderBy: { order: 'asc' }
        }
      }
    });

    return this.formatTripResponse(trip);
  }

  /**
   * Get trip by share code
   */
  async getTripByShareCode(shareCode: string): Promise<TripResponse> {
    const trip = await prisma.trip.findUnique({
      where: { 
        shareCode,
        isActive: true 
      },
      include: {
        stops: {
          orderBy: { order: 'asc' }
        }
      }
    });

    if (!trip) {
      throw new NotFoundError('Trip');
    }

    return this.formatTripResponse(trip);
  }

  /**
   * Update trip details
   */
  async updateTrip(shareCode: string, data: UpdateTripRequest): Promise<TripResponse> {
    // Check if trip exists
    const existingTrip = await prisma.trip.findUnique({
      where: { shareCode, isActive: true }
    });

    if (!existingTrip) {
      throw new NotFoundError('Trip');
    }

    const trip = await prisma.trip.update({
      where: { shareCode },
      data: {
        name: data.name,
        destination: data.destination,
      },
      include: {
        stops: {
          orderBy: { order: 'asc' }
        }
      }
    });

    const formattedTrip = this.formatTripResponse(trip);

    // Emit real-time update
    try {
      const wsService = getWebSocketService();
      wsService.emitTripUpdated(shareCode, formattedTrip);
    } catch (error) {
      console.warn('WebSocket service not available:', error);
    }

    return formattedTrip;
  }

  /**
   * Delete trip (soft delete)
   */
  async deleteTrip(shareCode: string): Promise<void> {
    const trip = await prisma.trip.findUnique({
      where: { shareCode, isActive: true }
    });

    if (!trip) {
      throw new NotFoundError('Trip');
    }

    await prisma.trip.update({
      where: { shareCode },
      data: { isActive: false }
    });
  }

  /**
   * Check if trip exists and is active
   */
  async tripExists(shareCode: string): Promise<boolean> {
    const trip = await prisma.trip.findUnique({
      where: { shareCode, isActive: true }
    });

    return !!trip;
  }

  /**
   * Get trip statistics
   */
  async getTripStats(shareCode: string): Promise<{
    stopCount: number;
    createdAt: Date;
    lastUpdated: Date;
  }> {
    const trip = await prisma.trip.findUnique({
      where: { shareCode, isActive: true },
      include: {
        _count: {
          select: { stops: true }
        }
      }
    });

    if (!trip) {
      throw new NotFoundError('Trip');
    }

    return {
      stopCount: trip._count.stops,
      createdAt: trip.createdAt,
      lastUpdated: trip.updatedAt,
    };
  }

  /**
   * Format database trip to API response
   */
  private formatTripResponse(trip: any): TripResponse {
    return {
      id: trip.id,
      shareCode: trip.shareCode,
      name: trip.name,
      destination: trip.destination as Location,
      stops: trip.stops.map((stop: any): StopResponse => ({
        id: stop.id,
        name: stop.name,
        latitude: stop.latitude,
        longitude: stop.longitude,
        address: stop.address,
        order: stop.order,
        addedAt: stop.addedAt.toISOString(),
      })),
      createdAt: trip.createdAt.toISOString(),
      updatedAt: trip.updatedAt.toISOString(),
    };
  }
}
