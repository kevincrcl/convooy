import { nanoid } from 'nanoid';
import request from 'supertest';
import { app } from '../src/app';
import { prisma } from '../src/services/database';
import { CreateTripRequest, Location } from '../src/models/types';

/**
 * Test Factory - Automatically tracks and cleans up created resources
 * 
 * This enables parallel test execution by ensuring each test only cleans up
 * its own resources, avoiding conflicts with other running tests.
 * 
 * Usage:
 *   let factory: TestFactory;
 *   
 *   beforeEach(() => {
 *     factory = new TestFactory();
 *   });
 *   
 *   afterEach(async () => {
 *     await factory.cleanup();
 *   });
 *   
 *   it('test', async () => {
 *     const trip = await factory.createTrip({ name: 'Test Trip' });
 *     // Trip is automatically tracked for cleanup
 *   });
 */
export class TestFactory {
  private createdTripIds: string[] = [];

  /**
   * Generate random coordinates (San Francisco area)
   */
  randomCoordinates() {
    return {
      latitude: 37.7749 + (Math.random() - 0.5) * 0.1,
      longitude: -122.4194 + (Math.random() - 0.5) * 0.1,
    };
  }

  /**
   * Generate random location
   */
  randomLocation(): Location {
    const coords = this.randomCoordinates();
    return {
      name: `Location ${nanoid(6)}`,
      address: `${Math.floor(Math.random() * 9999)} Test St, Test City, TC ${Math.floor(Math.random() * 90000 + 10000)}`,
      latitude: coords.latitude,
      longitude: coords.longitude,
    };
  }

  /**
   * Generate random trip name
   */
  randomTripName() {
    return `Trip ${nanoid(8)}`;
  }

  /**
   * Generate random stop name
   */
  randomStopName() {
    return `Stop ${nanoid(6)}`;
  }

  /**
   * Create a trip via API and automatically track it for cleanup
   * 
   * @param overrides - Optional overrides for trip data
   * @returns Supertest response
   */
  async createTrip(overrides?: Partial<CreateTripRequest>) {
    const tripData: CreateTripRequest = {
      name: overrides?.name ?? this.randomTripName(),
      destination: overrides?.destination ?? this.randomLocation(),
    };

    const response = await request(app)
      .post('/api/trips')
      .send(tripData);

    // Auto-track if successful
    if (response.status === 201 && response.body.data?.shareCode) {
      this.createdTripIds.push(response.body.data.shareCode);
    }

    return response;
  }

  /**
   * Get a trip via API
   */
  async getTrip(shareCode: string) {
    return await request(app)
      .get(`/api/trips/${shareCode}`);
  }

  /**
   * Update a trip via API
   */
  async updateTrip(shareCode: string, data: Partial<CreateTripRequest>) {
    return await request(app)
      .put(`/api/trips/${shareCode}`)
      .send(data);
  }

  /**
   * Delete a trip via API
   */
  async deleteTrip(shareCode: string) {
    return await request(app)
      .delete(`/api/trips/${shareCode}`);
  }

  /**
   * Join a trip via API
   */
  async joinTrip(shareCode: string) {
    return await request(app)
      .post(`/api/trips/join/${shareCode}`);
  }

  /**
   * Get trip stats via API
   */
  async getTripStats(shareCode: string) {
    return await request(app)
      .get(`/api/trips/${shareCode}/stats`);
  }

  /**
   * Create a stop for a trip via API
   */
  async createStop(shareCode: string, overrides?: {
    name?: string;
    address?: string;
    latitude?: number;
    longitude?: number;
  }) {
    const coords = this.randomCoordinates();
    const stopData = {
      name: overrides?.name ?? this.randomStopName(),
      address: overrides?.address ?? `${Math.floor(Math.random() * 9999)} Test St`,
      latitude: overrides?.latitude ?? coords.latitude,
      longitude: overrides?.longitude ?? coords.longitude,
    };

    return await request(app)
      .post(`/api/trips/${shareCode}/stops`)
      .send(stopData);
  }

  /**
   * Get all stops for a trip via API
   */
  async getStops(shareCode: string) {
    return await request(app)
      .get(`/api/trips/${shareCode}/stops`);
  }

  /**
   * Update a stop via API
   */
  async updateStop(shareCode: string, stopId: string, data: {
    name?: string;
    address?: string;
    latitude?: number;
    longitude?: number;
  }) {
    return await request(app)
      .put(`/api/trips/${shareCode}/stops/${stopId}`)
      .send(data);
  }

  /**
   * Delete a stop via API
   */
  async deleteStop(shareCode: string, stopId: string) {
    return await request(app)
      .delete(`/api/trips/${shareCode}/stops/${stopId}`);
  }

  /**
   * Reorder stops via API
   */
  async reorderStops(shareCode: string, stopIds: string[]) {
    return await request(app)
      .put(`/api/trips/${shareCode}/stops/reorder`)
      .send({ stopIds });
  }

  /**
   * Clean up all resources created by this factory
   * 
   * This is called automatically in afterEach hooks.
   * Deletes trips (which cascades to stops via foreign key).
   */
  async cleanup() {
    // Delete all tracked trips (stops cascade automatically)
    for (const shareCode of this.createdTripIds) {
      try {
        await prisma.trip.delete({
          where: { shareCode },
        });
      } catch (error) {
        // Trip might have been deleted by the test itself, that's fine
      }
    }

    // Clear the tracking array
    this.createdTripIds = [];
  }

  /**
   * Get list of tracked trip IDs (for debugging)
   */
  getTrackedTrips() {
    return [...this.createdTripIds];
  }
}

/**
 * Helper function for creating trip payloads without going through API
 * Useful for invalid data tests
 */
export function createTripPayload(overrides?: Partial<CreateTripRequest>): CreateTripRequest {
  const factory = new TestFactory();
  return {
    name: overrides?.name ?? factory.randomTripName(),
    destination: overrides?.destination ?? factory.randomLocation(),
  };
}

/**
 * Helper function for creating stop payloads without going through API
 * Useful for invalid data tests
 */
export function createStopPayload(overrides?: {
  name?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
}) {
  const factory = new TestFactory();
  const coords = factory.randomCoordinates();
  
  return {
    name: overrides?.name ?? factory.randomStopName(),
    address: overrides?.address ?? `${Math.floor(Math.random() * 9999)} Test St`,
    latitude: overrides?.latitude ?? coords.latitude,
    longitude: overrides?.longitude ?? coords.longitude,
  };
}

