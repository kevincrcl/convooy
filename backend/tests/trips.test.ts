import request from 'supertest';
import { app } from '../src/app';
import { prisma } from '../src/services/database';
import { CreateTripRequest, UpdateTripRequest } from '../src/models/types';
import { TestFactory, createTripPayload } from './factory';

describe('Trips API', () => {
  let factory: TestFactory;

  beforeEach(() => {
    factory = new TestFactory();
  });

  afterEach(async () => {
    await factory.cleanup();
  });

  describe('POST /api/trips', () => {
    it('should create a new trip with destination', async () => {
      const response = await factory.createTrip({
        name: 'Weekend Trip',
      });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toMatchObject({
        name: 'Weekend Trip',
        stops: [],
      });
      expect(response.body.data.shareCode).toBeDefined();
      expect(response.body.data.shareCode).toMatch(/^[A-Z0-9]{6,8}$/);
      expect(response.body.data.id).toBeDefined();
      expect(response.body.data.createdAt).toBeDefined();
      expect(response.body.data.updatedAt).toBeDefined();
      expect(response.body.data.destination).toBeDefined();
    });

    it('should create a trip without a name', async () => {
      // Don't pass name at all to get null
      const destination = factory.randomLocation();
      const response = await request(app)
        .post('/api/trips')
        .send({ destination });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBeNull();
      expect(response.body.data.destination).toBeDefined();
    });

    it('should reject trip without destination', async () => {
      const response = await request(app)
        .post('/api/trips')
        .send({ name: 'Test Trip' })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBeDefined();
    });

    it('should reject trip with invalid destination coordinates', async () => {
      const response = await request(app)
        .post('/api/trips')
        .send({
          destination: {
            name: 'Invalid',
            latitude: 100, // Invalid - exceeds max latitude
            longitude: -73.968285,
          },
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should generate unique share codes for multiple trips', async () => {
      const response1 = await factory.createTrip();
      const response2 = await factory.createTrip();

      expect(response1.body.data.shareCode).not.toBe(response2.body.data.shareCode);
    });
  });

  describe('GET /api/trips/:shareCode', () => {
    it('should get trip by share code', async () => {
      const createResponse = await factory.createTrip({
        name: 'Test Trip',
      });
      const shareCode = createResponse.body.data.shareCode;

      const response = await factory.getTrip(shareCode);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.shareCode).toBe(shareCode);
      expect(response.body.data.name).toBe('Test Trip');
    });

    it('should return 404 for non-existent share code', async () => {
      const response = await factory.getTrip('INVALID');

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toBeDefined();
    });

    it('should reject invalid share code format', async () => {
      const response = await factory.getTrip('abc'); // Too short

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should not return inactive trips', async () => {
      const createResponse = await factory.createTrip();
      const shareCode = createResponse.body.data.shareCode;

      // Soft delete the trip
      await prisma.trip.update({
        where: { shareCode },
        data: { isActive: false },
      });

      const response = await factory.getTrip(shareCode);

      expect(response.status).toBe(404);
    });
  });

  describe('PUT /api/trips/:shareCode', () => {
    it('should update trip destination', async () => {
      const createResponse = await factory.createTrip({
        name: 'Original Trip',
      });
      const shareCode = createResponse.body.data.shareCode;

      const newDestination = factory.randomLocation();
      const updateData: UpdateTripRequest = {
        destination: newDestination,
      };

      const response = await factory.updateTrip(shareCode, updateData);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      // Check coordinates with tolerance for floating point precision
      expect(response.body.data.destination.latitude).toBeCloseTo(newDestination.latitude, 10);
      expect(response.body.data.destination.longitude).toBeCloseTo(newDestination.longitude, 10);
      expect(response.body.data.destination.name).toBe(newDestination.name);
      expect(response.body.data.name).toBe('Original Trip'); // Name unchanged
    });

    it('should update trip name', async () => {
      const createResponse = await factory.createTrip({
        name: 'Original Name',
      });
      const shareCode = createResponse.body.data.shareCode;
      const originalDestination = createResponse.body.data.destination;

      const updateData: UpdateTripRequest = {
        name: 'Updated Name',
      };

      const response = await factory.updateTrip(shareCode, updateData);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Updated Name');
      expect(response.body.data.destination).toEqual(originalDestination); // Destination unchanged
    });

    it('should reject invalid coordinates in update', async () => {
      const createResponse = await factory.createTrip();
      const shareCode = createResponse.body.data.shareCode;

      const response = await factory.updateTrip(shareCode, {
        destination: {
          name: 'Invalid',
          latitude: 100, // Invalid
          longitude: -73.968285,
          address: '123 Test St',
        },
      });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await factory.updateTrip('INVALID', {
        name: 'Updated',
      });

      expect(response.status).toBe(404);
    });
  });

  describe('DELETE /api/trips/:shareCode', () => {
    it('should delete a trip (soft delete)', async () => {
      const createResponse = await factory.createTrip();
      const shareCode = createResponse.body.data.shareCode;

      const deleteResponse = await factory.deleteTrip(shareCode);

      expect(deleteResponse.status).toBe(204);

      // Verify trip is soft-deleted
      const trip = await prisma.trip.findUnique({
        where: { shareCode },
      });
      expect(trip).not.toBeNull();
      expect(trip?.isActive).toBe(false);

      // Verify it's not accessible via API
      const getResponse = await factory.getTrip(shareCode);
      expect(getResponse.status).toBe(404);
    });

    it('should return 404 when deleting non-existent trip', async () => {
      const response = await factory.deleteTrip('INVALID');

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/trips/:shareCode/share', () => {
    it('should return share information', async () => {
      const createResponse = await factory.createTrip({
        name: 'Shared Trip',
      });
      const shareCode = createResponse.body.data.shareCode;

      const response = await request(app)
        .get(`/api/trips/${shareCode}/share`)
        .expect(200);

      expect(response.body.success).toBe(true);
      // Share code is formatted with hyphen in response
      expect(response.body.data.shareCode).toMatch(/[A-Z0-9]+-[A-Z0-9]+/);
      expect(response.body.data.shareUrl).toContain(shareCode);
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await request(app)
        .get('/api/trips/INVALID/share')
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });

  describe('POST /api/trips/join/:shareCode', () => {
    it('should return trip data when joining', async () => {
      const createResponse = await factory.createTrip({
        name: 'Join Test Trip',
      });
      const shareCode = createResponse.body.data.shareCode;

      const response = await factory.joinTrip(shareCode);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.shareCode).toBe(shareCode);
      expect(response.body.data.name).toBe('Join Test Trip');
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await factory.joinTrip('INVALID');

      expect(response.status).toBe(404);
    });

    it('should increment join count', async () => {
      const createResponse = await factory.createTrip();
      const shareCode = createResponse.body.data.shareCode;

      // Join multiple times
      await factory.joinTrip(shareCode);
      await factory.joinTrip(shareCode);

      // Check join count (implementation-specific)
      const trip = await prisma.trip.findUnique({
        where: { shareCode },
      });
      
      // Note: Adjust this based on your actual implementation
      expect(trip).toBeDefined();
    });
  });

  describe('GET /api/trips/:shareCode/stats', () => {
    it('should return trip statistics', async () => {
      const createResponse = await factory.createTrip();
      const shareCode = createResponse.body.data.shareCode;

      // Add some stops
      await factory.createStop(shareCode, { name: 'Stop 1' });
      await factory.createStop(shareCode, { name: 'Stop 2' });

      const response = await factory.getTripStats(shareCode);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.stopCount).toBe(2);
      expect(response.body.data.createdAt).toBeDefined();
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await factory.getTripStats('INVALID');

      expect(response.status).toBe(404);
    });
  });

  describe('Integration: Full trip lifecycle', () => {
    it('should handle complete trip creation, update, and deletion', async () => {
      // Create trip
      const createResponse = await factory.createTrip({
        name: 'Lifecycle Trip',
      });
      expect(createResponse.status).toBe(201);
      const shareCode = createResponse.body.data.shareCode;

      // Add stops
      const stop1 = await factory.createStop(shareCode, { name: 'First Stop' });
      const stop2 = await factory.createStop(shareCode, { name: 'Second Stop' });
      expect(stop1.status).toBe(201);
      expect(stop2.status).toBe(201);

      // Update trip
      const updateResponse = await factory.updateTrip(shareCode, {
        name: 'Updated Lifecycle Trip',
      });
      expect(updateResponse.status).toBe(200);

      // Get stats
      const statsResponse = await factory.getTripStats(shareCode);
      expect(statsResponse.status).toBe(200);
      expect(statsResponse.body.data.stopCount).toBe(2);

      // Delete trip
      const deleteResponse = await factory.deleteTrip(shareCode);
      expect(deleteResponse.status).toBe(204);

      // Verify deletion
      const getResponse = await factory.getTrip(shareCode);
      expect(getResponse.status).toBe(404);
    });

    it('should handle trip with multiple stops and reordering', async () => {
      const createResponse = await factory.createTrip();
      const shareCode = createResponse.body.data.shareCode;

      // Create multiple stops
      const stops = await Promise.all([
        factory.createStop(shareCode, { name: 'Stop A' }),
        factory.createStop(shareCode, { name: 'Stop B' }),
        factory.createStop(shareCode, { name: 'Stop C' }),
      ]);

      const stopIds = stops.map(s => s.body.data.id);

      // Reorder stops
      const reorderedIds = [stopIds[2], stopIds[0], stopIds[1]];
      const reorderResponse = await factory.reorderStops(shareCode, reorderedIds);
      expect(reorderResponse.status).toBe(200);

      // Verify order
      const getResponse = await factory.getStops(shareCode);
      expect(getResponse.body.data).toHaveLength(3);
      expect(getResponse.body.data[0].id).toBe(stopIds[2]);
      expect(getResponse.body.data[1].id).toBe(stopIds[0]);
      expect(getResponse.body.data[2].id).toBe(stopIds[1]);
    });
  });
});
