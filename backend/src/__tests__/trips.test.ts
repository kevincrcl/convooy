import request from 'supertest';
import { app } from '../app';
import { prisma } from '../services/database';
import { CreateTripRequest, UpdateTripRequest, Location } from '../models/types';

describe('Trips API', () => {
  const mockDestination: Location = {
    name: 'Central Park',
    latitude: 40.785091,
    longitude: -73.968285,
    address: 'Central Park, New York, NY 10024',
  };

  describe('POST /api/trips', () => {
    it('should create a new trip with destination', async () => {
      const tripData: CreateTripRequest = {
        name: 'Weekend Trip',
        destination: mockDestination,
      };

      const response = await request(app)
        .post('/api/trips')
        .send(tripData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toMatchObject({
        name: 'Weekend Trip',
        destination: mockDestination,
        stops: [],
      });
      expect(response.body.data.shareCode).toBeDefined();
      expect(response.body.data.shareCode).toMatch(/^[A-Z0-9]{6,8}$/);
      expect(response.body.data.id).toBeDefined();
      expect(response.body.data.createdAt).toBeDefined();
      expect(response.body.data.updatedAt).toBeDefined();
    });

    it('should create a trip without a name', async () => {
      const tripData: CreateTripRequest = {
        destination: mockDestination,
      };

      const response = await request(app)
        .post('/api/trips')
        .send(tripData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBeNull();
      expect(response.body.data.destination).toEqual(mockDestination);
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
      const tripData = {
        destination: {
          name: 'Invalid',
          latitude: 100, // Invalid - exceeds max latitude
          longitude: -73.968285,
        },
      };

      const response = await request(app)
        .post('/api/trips')
        .send(tripData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should generate unique share codes for multiple trips', async () => {
      const tripData: CreateTripRequest = {
        destination: mockDestination,
      };

      const response1 = await request(app)
        .post('/api/trips')
        .send(tripData)
        .expect(201);

      const response2 = await request(app)
        .post('/api/trips')
        .send(tripData)
        .expect(201);

      expect(response1.body.data.shareCode).not.toBe(response2.body.data.shareCode);
    });
  });

  describe('GET /api/trips/:shareCode', () => {
    let testShareCode: string;

    beforeEach(async () => {
      const tripData: CreateTripRequest = {
        name: 'Test Trip',
        destination: mockDestination,
      };

      const response = await request(app)
        .post('/api/trips')
        .send(tripData);

      testShareCode = response.body.data.shareCode;
    });

    it('should get trip by share code', async () => {
      const response = await request(app)
        .get(`/api/trips/${testShareCode}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.shareCode).toBe(testShareCode);
      expect(response.body.data.name).toBe('Test Trip');
      expect(response.body.data.destination).toEqual(mockDestination);
    });

    it('should return 404 for non-existent share code', async () => {
      const response = await request(app)
        .get('/api/trips/INVALID')
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBeDefined();
    });

    it('should reject invalid share code format', async () => {
      const response = await request(app)
        .get('/api/trips/abc') // Too short
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should not return inactive trips', async () => {
      // Soft delete the trip
      await prisma.trip.update({
        where: { shareCode: testShareCode },
        data: { isActive: false },
      });

      const response = await request(app)
        .get(`/api/trips/${testShareCode}`)
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });

  describe('PUT /api/trips/:shareCode', () => {
    let testShareCode: string;

    beforeEach(async () => {
      const tripData: CreateTripRequest = {
        name: 'Original Trip',
        destination: mockDestination,
      };

      const response = await request(app)
        .post('/api/trips')
        .send(tripData);

      testShareCode = response.body.data.shareCode;
    });

    it('should update trip name', async () => {
      const updateData: UpdateTripRequest = {
        name: 'Updated Trip Name',
      };

      const response = await request(app)
        .put(`/api/trips/${testShareCode}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Updated Trip Name');
      expect(response.body.data.destination).toEqual(mockDestination);
    });

    it('should update trip destination', async () => {
      const newDestination: Location = {
        name: 'Times Square',
        latitude: 40.758896,
        longitude: -73.985130,
        address: 'Times Square, New York, NY',
      };

      const updateData: UpdateTripRequest = {
        destination: newDestination,
      };

      const response = await request(app)
        .put(`/api/trips/${testShareCode}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.destination).toEqual(newDestination);
      expect(response.body.data.name).toBe('Original Trip');
    });

    it('should update both name and destination', async () => {
      const newDestination: Location = {
        name: 'Brooklyn Bridge',
        latitude: 40.706086,
        longitude: -73.996864,
      };

      const updateData: UpdateTripRequest = {
        name: 'Brooklyn Adventure',
        destination: newDestination,
      };

      const response = await request(app)
        .put(`/api/trips/${testShareCode}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Brooklyn Adventure');
      expect(response.body.data.destination).toEqual(newDestination);
    });

    it('should return 404 for non-existent trip', async () => {
      const updateData: UpdateTripRequest = {
        name: 'Updated Name',
      };

      const response = await request(app)
        .put('/api/trips/INVALID')
        .send(updateData)
        .expect(404);

      expect(response.body.success).toBe(false);
    });

    it('should reject invalid update data', async () => {
      const response = await request(app)
        .put(`/api/trips/${testShareCode}`)
        .send({
          destination: {
            name: 'Test',
            latitude: 'invalid', // Should be number
            longitude: -73.0,
          },
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should preserve share code after update', async () => {
      const updateData: UpdateTripRequest = {
        name: 'New Name',
      };

      const response = await request(app)
        .put(`/api/trips/${testShareCode}`)
        .send(updateData)
        .expect(200);

      expect(response.body.data.shareCode).toBe(testShareCode);
    });
  });

  describe('DELETE /api/trips/:shareCode', () => {
    let testShareCode: string;

    beforeEach(async () => {
      const tripData: CreateTripRequest = {
        name: 'Trip to Delete',
        destination: mockDestination,
      };

      const response = await request(app)
        .post('/api/trips')
        .send(tripData);

      testShareCode = response.body.data.shareCode;
    });

    it('should soft delete a trip', async () => {
      await request(app)
        .delete(`/api/trips/${testShareCode}`)
        .expect(204);

      // Verify trip is soft deleted (not accessible via API)
      await request(app)
        .get(`/api/trips/${testShareCode}`)
        .expect(404);

      // Verify trip still exists in database but is inactive
      const trip = await prisma.trip.findUnique({
        where: { shareCode: testShareCode },
      });
      expect(trip).not.toBeNull();
      expect(trip?.isActive).toBe(false);
    });

    it('should return 404 when deleting non-existent trip', async () => {
      const response = await request(app)
        .delete('/api/trips/INVALID')
        .expect(404);

      expect(response.body.success).toBe(false);
    });

    it('should return 404 when deleting already deleted trip', async () => {
      await request(app)
        .delete(`/api/trips/${testShareCode}`)
        .expect(204);

      // Try to delete again
      await request(app)
        .delete(`/api/trips/${testShareCode}`)
        .expect(404);
    });
  });

  describe('GET /api/trips/:shareCode/share', () => {
    let testShareCode: string;

    beforeEach(async () => {
      const tripData: CreateTripRequest = {
        destination: mockDestination,
      };

      const response = await request(app)
        .post('/api/trips')
        .send(tripData);

      testShareCode = response.body.data.shareCode;
    });

    it('should get share information for a trip', async () => {
      const response = await request(app)
        .get(`/api/trips/${testShareCode}/share`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toMatchObject({
        shareCode: expect.any(String),
        shareUrl: expect.stringContaining(testShareCode),
        qrCodeUrl: expect.stringContaining(testShareCode),
      });
    });

    it('should format share code properly', async () => {
      const response = await request(app)
        .get(`/api/trips/${testShareCode}/share`)
        .expect(200);

      // Share code should be formatted (e.g., with dashes or uppercase)
      expect(response.body.data.shareCode).toBeDefined();
      expect(typeof response.body.data.shareCode).toBe('string');
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await request(app)
        .get('/api/trips/INVALID/share')
        .expect(404);

      expect(response.body.success).toBe(false);
    });

    it('should include correct base URL in share URL', async () => {
      const originalUrl = process.env.FRONTEND_URL;
      process.env.FRONTEND_URL = 'https://example.com';

      const response = await request(app)
        .get(`/api/trips/${testShareCode}/share`)
        .expect(200);

      expect(response.body.data.shareUrl).toContain('https://example.com');

      // Restore original
      if (originalUrl) {
        process.env.FRONTEND_URL = originalUrl;
      } else {
        delete process.env.FRONTEND_URL;
      }
    });
  });

  describe('POST /api/trips/join/:shareCode', () => {
    let testShareCode: string;

    beforeEach(async () => {
      const tripData: CreateTripRequest = {
        name: 'Trip to Join',
        destination: mockDestination,
      };

      const response = await request(app)
        .post('/api/trips')
        .send(tripData);

      testShareCode = response.body.data.shareCode;
    });

    it('should join a trip successfully', async () => {
      const response = await request(app)
        .post(`/api/trips/join/${testShareCode}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.shareCode).toBe(testShareCode);
      expect(response.body.message).toBe('Successfully joined trip');
    });

    it('should return trip data when joining', async () => {
      const response = await request(app)
        .post(`/api/trips/join/${testShareCode}`)
        .expect(200);

      expect(response.body.data).toMatchObject({
        shareCode: testShareCode,
        name: 'Trip to Join',
        destination: mockDestination,
        stops: [],
      });
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await request(app)
        .post('/api/trips/join/INVALID')
        .expect(404);

      expect(response.body.success).toBe(false);
    });

    it('should allow multiple users to join the same trip', async () => {
      // First user joins
      const response1 = await request(app)
        .post(`/api/trips/join/${testShareCode}`)
        .expect(200);

      // Second user joins
      const response2 = await request(app)
        .post(`/api/trips/join/${testShareCode}`)
        .expect(200);

      expect(response1.body.success).toBe(true);
      expect(response2.body.success).toBe(true);
      expect(response1.body.data.shareCode).toBe(response2.body.data.shareCode);
    });
  });

  describe('GET /api/trips/:shareCode/stats', () => {
    let testShareCode: string;

    beforeEach(async () => {
      const tripData: CreateTripRequest = {
        name: 'Stats Trip',
        destination: mockDestination,
      };

      const response = await request(app)
        .post('/api/trips')
        .send(tripData);

      testShareCode = response.body.data.shareCode;
    });

    it('should get trip statistics', async () => {
      const response = await request(app)
        .get(`/api/trips/${testShareCode}/stats`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toMatchObject({
        stopCount: 0,
        createdAt: expect.any(String),
        lastUpdated: expect.any(String),
      });
    });

    it('should return correct stop count', async () => {
      // Add some stops to the trip
      const trip = await prisma.trip.findUnique({
        where: { shareCode: testShareCode },
      });

      await prisma.stop.createMany({
        data: [
          {
            tripId: trip!.id,
            name: 'Stop 1',
            latitude: 40.7,
            longitude: -73.9,
            order: 0,
          },
          {
            tripId: trip!.id,
            name: 'Stop 2',
            latitude: 40.8,
            longitude: -73.8,
            order: 1,
          },
        ],
      });

      const response = await request(app)
        .get(`/api/trips/${testShareCode}/stats`)
        .expect(200);

      expect(response.body.data.stopCount).toBe(2);
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await request(app)
        .get('/api/trips/INVALID/stats')
        .expect(404);

      expect(response.body.success).toBe(false);
    });

    it('should return valid date formats', async () => {
      const response = await request(app)
        .get(`/api/trips/${testShareCode}/stats`)
        .expect(200);

      const createdAt = new Date(response.body.data.createdAt);
      const lastUpdated = new Date(response.body.data.lastUpdated);

      expect(createdAt.toString()).not.toBe('Invalid Date');
      expect(lastUpdated.toString()).not.toBe('Invalid Date');
    });
  });

  describe('Integration: Trip lifecycle', () => {
    it('should handle complete trip lifecycle', async () => {
      // 1. Create trip
      const createResponse = await request(app)
        .post('/api/trips')
        .send({
          name: 'Lifecycle Test',
          destination: mockDestination,
        })
        .expect(201);

      const shareCode = createResponse.body.data.shareCode;

      // 2. Get trip
      await request(app)
        .get(`/api/trips/${shareCode}`)
        .expect(200);

      // 3. Get share info
      await request(app)
        .get(`/api/trips/${shareCode}/share`)
        .expect(200);

      // 4. Join trip
      await request(app)
        .post(`/api/trips/join/${shareCode}`)
        .expect(200);

      // 5. Update trip
      await request(app)
        .put(`/api/trips/${shareCode}`)
        .send({ name: 'Updated Lifecycle Test' })
        .expect(200);

      // 6. Get stats
      await request(app)
        .get(`/api/trips/${shareCode}/stats`)
        .expect(200);

      // 7. Delete trip
      await request(app)
        .delete(`/api/trips/${shareCode}`)
        .expect(204);

      // 8. Verify trip is gone
      await request(app)
        .get(`/api/trips/${shareCode}`)
        .expect(404);
    });
  });
});

