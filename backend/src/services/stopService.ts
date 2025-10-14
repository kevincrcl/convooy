import { prisma } from './database';
import { NotFoundError, ValidationError } from '../utils/errors';
import { getWebSocketService } from './websocketService';
import { 
  CreateStopRequest, 
  UpdateStopRequest, 
  StopResponse,
  ReorderStopsRequest 
} from '../models/types';

// Internal types for better type safety
interface StopUpdateData {
  name?: string;
  latitude?: number;
  longitude?: number;
  address?: string | null;
}

interface StopWhereClause {
  tripId: string;
  id?: { not: string };
  latitude: { gte: number; lte: number };
  longitude: { gte: number; lte: number };
}

export class StopService {
  /**
   * Add a new stop to a trip
   */
  async addStop(shareCode: string, data: CreateStopRequest): Promise<StopResponse> {
    // Verify trip exists
    const trip = await prisma.trip.findUnique({
      where: { shareCode, isActive: true },
      include: {
        stops: {
          orderBy: { order: 'desc' },
          take: 1
        }
      }
    });

    if (!trip) {
      throw new NotFoundError('Trip');
    }

    // Check if location is already a stop (within ~10 meters)
    const existingStop = await this.findNearbyStop(trip.id, data.latitude, data.longitude);
    if (existingStop) {
      throw new ValidationError('A stop already exists at this location');
    }

    // Calculate next order position
    const nextOrder = trip.stops.length > 0 ? trip.stops[0]!.order + 1 : 0;

    const stop = await prisma.stop.create({
      data: {
        tripId: trip.id,
        name: data.name,
        latitude: data.latitude,
        longitude: data.longitude,
        address: data.address || null,
        order: nextOrder,
      }
    });

    const formattedStop = this.formatStopResponse(stop);

    // Emit real-time update
    try {
      const wsService = getWebSocketService();
      wsService.emitStopAdded(shareCode, formattedStop);
    } catch (error) {
      console.warn('WebSocket service not available:', error);
    }

    return formattedStop;
  }

  /**
   * Update an existing stop
   */
  async updateStop(shareCode: string, stopId: string, data: UpdateStopRequest): Promise<StopResponse> {
    // Verify trip and stop exist
    const trip = await prisma.trip.findUnique({
      where: { shareCode, isActive: true }
    });

    if (!trip) {
      throw new NotFoundError('Trip');
    }

    const existingStop = await prisma.stop.findFirst({
      where: { 
        id: stopId, 
        tripId: trip.id 
      }
    });

    if (!existingStop) {
      throw new NotFoundError('Stop');
    }

    // If coordinates are being updated, check for nearby stops
    if (data.latitude !== undefined && data.longitude !== undefined) {
      const nearbyStop = await this.findNearbyStop(
        trip.id, 
        data.latitude, 
        data.longitude, 
        stopId
      );
      
      if (nearbyStop) {
        throw new ValidationError('A stop already exists at this location');
      }
    }

    // Build update data object, filtering out undefined values
    const updateData: StopUpdateData = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.latitude !== undefined) updateData.latitude = data.latitude;
    if (data.longitude !== undefined) updateData.longitude = data.longitude;
    if (data.address !== undefined) updateData.address = data.address || null;

    const stop = await prisma.stop.update({
      where: { id: stopId },
      data: updateData
    });

    return this.formatStopResponse(stop);
  }

  /**
   * Remove a stop from a trip
   */
  async removeStop(shareCode: string, stopId: string): Promise<void> {
    // Verify trip exists
    const trip = await prisma.trip.findUnique({
      where: { shareCode, isActive: true }
    });

    if (!trip) {
      throw new NotFoundError('Trip');
    }

    // Verify stop exists and belongs to trip
    const stop = await prisma.stop.findFirst({
      where: { 
        id: stopId, 
        tripId: trip.id 
      }
    });

    if (!stop) {
      throw new NotFoundError('Stop');
    }

    // Delete the stop
    await prisma.stop.delete({
      where: { id: stopId }
    });

    // Reorder remaining stops to fill the gap
    await this.reorderStopsAfterDeletion(trip.id, stop.order);

    // Emit real-time update
    try {
      const wsService = getWebSocketService();
      wsService.emitStopRemoved(shareCode, stopId);
    } catch (error) {
      console.warn('WebSocket service not available:', error);
    }
  }

  /**
   * Reorder stops in a trip
   */
  async reorderStops(shareCode: string, data: ReorderStopsRequest): Promise<StopResponse[]> {
    // Verify trip exists
    const trip = await prisma.trip.findUnique({
      where: { shareCode, isActive: true },
      include: {
        stops: true
      }
    });

    if (!trip) {
      throw new NotFoundError('Trip');
    }

    // Verify all stop IDs belong to this trip
    const tripStopIds = new Set(trip.stops.map(stop => stop.id));
    const invalidStopIds = data.stopIds.filter(id => !tripStopIds.has(id));
    
    if (invalidStopIds.length > 0) {
      throw new ValidationError(`Invalid stop IDs: ${invalidStopIds.join(', ')}`);
    }

    // Verify all stops are included in the reorder
    if (data.stopIds.length !== trip.stops.length) {
      throw new ValidationError('All stops must be included in reorder operation');
    }

    // Update stop orders in a transaction
    const updatedStops = await prisma.$transaction(
      data.stopIds.map((stopId, index) =>
        prisma.stop.update({
          where: { id: stopId },
          data: { order: index }
        })
      )
    );

    const formattedStops = updatedStops.map(stop => this.formatStopResponse(stop));

    // Emit real-time update
    try {
      const wsService = getWebSocketService();
      wsService.emitStopsReordered(shareCode, formattedStops);
    } catch (error) {
      console.warn('WebSocket service not available:', error);
    }

    return formattedStops;
  }

  /**
   * Get all stops for a trip
   */
  async getStopsByTrip(shareCode: string): Promise<StopResponse[]> {
    const trip = await prisma.trip.findUnique({
      where: { shareCode, isActive: true },
      include: {
        stops: {
          orderBy: { order: 'asc' }
        }
      }
    });

    if (!trip) {
      throw new NotFoundError('Trip');
    }

    return trip.stops.map(stop => this.formatStopResponse(stop));
  }

  /**
   * Find nearby stop within ~10 meters
   */
  private async findNearbyStop(
    tripId: string, 
    latitude: number, 
    longitude: number, 
    excludeStopId?: string
  ): Promise<{ id: string; latitude: number; longitude: number } | null> {
    // Simple distance calculation (not perfect for all latitudes, but good enough for ~10m)
    const latDelta = 0.0001; // ~11 meters at equator
    const lonDelta = 0.0001; // ~11 meters at equator

    // Build where clause, filtering out undefined values
    const whereClause: StopWhereClause = {
      tripId,
      latitude: {
        gte: latitude - latDelta,
        lte: latitude + latDelta,
      },
      longitude: {
        gte: longitude - lonDelta,
        lte: longitude + lonDelta,
      }
    };

    if (excludeStopId) {
      whereClause.id = { not: excludeStopId };
    }

    const stops = await prisma.stop.findMany({
      where: whereClause
    });

    // More precise distance check
    for (const stop of stops) {
      const distance = this.calculateDistance(
        latitude, longitude,
        stop.latitude, stop.longitude
      );
      
      if (distance < 10) { // 10 meters
        return stop;
      }
    }

    return null;
  }

  /**
   * Calculate distance between two coordinates in meters
   */
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371e3; // Earth's radius in meters
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lon2 - lon1) * Math.PI / 180;

    const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ/2) * Math.sin(Δλ/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

    return R * c;
  }

  /**
   * Reorder stops after deletion to fill gaps
   */
  private async reorderStopsAfterDeletion(tripId: string, deletedOrder: number): Promise<void> {
    await prisma.stop.updateMany({
      where: {
        tripId,
        order: { gt: deletedOrder }
      },
      data: {
        order: { decrement: 1 }
      }
    });
  }

  /**
   * Format database stop to API response
   */
  private formatStopResponse(stop: {
    id: string;
    name: string;
    latitude: number;
    longitude: number;
    address: string | null;
    order: number;
    addedAt: Date;
  }): StopResponse {
    const response: StopResponse = {
      id: stop.id,
      name: stop.name,
      latitude: stop.latitude,
      longitude: stop.longitude,
      order: stop.order,
      addedAt: stop.addedAt.toISOString(),
    };

    // Only include address if it's not null
    if (stop.address) {
      response.address = stop.address;
    }

    return response;
  }
}
