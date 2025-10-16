import request from 'supertest';
import { app } from '../app';
import { prisma } from '../services/database';
import { CreateStopRequest, UpdateStopRequest, ReorderStopsRequest } from '../models/types';

describe('Stops API', () => {
  let testShareCode: string;
  let testTripId: string;

  // Helper function to create a test trip before each test
  beforeEach(async () => {
    const tripResponse = await request(app)
      .post('/api/trips')
      .send({
        name: 'Test Trip',
        destination: {
          name: 'Final Destination',
          latitude: 40.7589,
          longitude: -73.9851,
          address: '123 Main St, New York, NY',
        },
      });

    testShareCode = tripResponse.body.data.shareCode;
    testTripId = tripResponse.body.data.id;
  });

  describe('POST /api/trips/:shareCode/stops', () => {
    it('should add a stop to a trip', async () => {
      const stopData: CreateStopRequest = {
        name: 'Coffee Shop',
        latitude: 40.7580,
        longitude: -73.9855,
        address: '456 Coffee St, New York, NY',
      };

      const response = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send(stopData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toMatchObject({
        name: 'Coffee Shop',
        latitude: 40.7580,
        longitude: -73.9855,
        address: '456 Coffee St, New York, NY',
        order: 0, // First stop
      });
      expect(response.body.data.id).toBeDefined();
      expect(response.body.data.addedAt).toBeDefined();
    });

    it('should add stop without address', async () => {
      const stopData: CreateStopRequest = {
        name: 'Park',
        latitude: 40.7590,
        longitude: -73.9860,
      };

      const response = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send(stopData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Park');
      expect(response.body.data.address).toBeUndefined();
    });

    it('should add multiple stops in order', async () => {
      const stop1 = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Stop 1',
          latitude: 40.7580,
          longitude: -73.9855,
        })
        .expect(201);

      const stop2 = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Stop 2',
          latitude: 40.7590,
          longitude: -73.9860,
        })
        .expect(201);

      expect(stop1.body.data.order).toBe(0);
      expect(stop2.body.data.order).toBe(1);
    });

    it('should reject stop with invalid coordinates', async () => {
      const response = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Invalid Stop',
          latitude: 100, // Invalid latitude
          longitude: -73.9855,
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should reject stop without required fields', async () => {
      const response = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          latitude: 40.7580,
          longitude: -73.9855,
          // Missing name
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await request(app)
        .post('/api/trips/INVALID/stops')
        .send({
          name: 'Stop',
          latitude: 40.7580,
          longitude: -73.9855,
        })
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/trips/:shareCode/stops', () => {
    it('should get empty array for trip with no stops', async () => {
      const response = await request(app)
        .get(`/api/trips/${testShareCode}/stops`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual([]);
    });

    it('should get all stops for a trip', async () => {
      // Add multiple stops
      await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Stop 1',
          latitude: 40.7580,
          longitude: -73.9855,
        });

      await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Stop 2',
          latitude: 40.7590,
          longitude: -73.9860,
        });

      const response = await request(app)
        .get(`/api/trips/${testShareCode}/stops`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(2);
      expect(response.body.data[0].name).toBe('Stop 1');
      expect(response.body.data[1].name).toBe('Stop 2');
    });

    it('should return stops in correct order', async () => {
      // Add stops
      await request(app).post(`/api/trips/${testShareCode}/stops`).send({
        name: 'First',
        latitude: 40.7580,
        longitude: -73.9855,
      });

      await request(app).post(`/api/trips/${testShareCode}/stops`).send({
        name: 'Second',
        latitude: 40.7590,
        longitude: -73.9860,
      });

      await request(app).post(`/api/trips/${testShareCode}/stops`).send({
        name: 'Third',
        latitude: 40.7600,
        longitude: -73.9865,
      });

      const response = await request(app)
        .get(`/api/trips/${testShareCode}/stops`)
        .expect(200);

      expect(response.body.data[0].order).toBe(0);
      expect(response.body.data[1].order).toBe(1);
      expect(response.body.data[2].order).toBe(2);
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await request(app)
        .get('/api/trips/INVALID/stops')
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });

  describe('PUT /api/trips/:shareCode/stops/:stopId', () => {
    let testStopId: string;

    beforeEach(async () => {
      const stopResponse = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Original Stop',
          latitude: 40.7580,
          longitude: -73.9855,
          address: 'Original Address',
        });

      testStopId = stopResponse.body.data.id;
    });

    it('should update stop name', async () => {
      const updateData: UpdateStopRequest = {
        name: 'Updated Stop',
      };

      const response = await request(app)
        .put(`/api/trips/${testShareCode}/stops/${testStopId}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Updated Stop');
      expect(response.body.data.latitude).toBe(40.7580); // Unchanged
    });

    it('should update stop coordinates', async () => {
      const updateData: UpdateStopRequest = {
        latitude: 40.7600,
        longitude: -73.9870,
      };

      const response = await request(app)
        .put(`/api/trips/${testShareCode}/stops/${testStopId}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.latitude).toBe(40.7600);
      expect(response.body.data.longitude).toBe(-73.9870);
      expect(response.body.data.name).toBe('Original Stop'); // Unchanged
    });

    it('should update stop address', async () => {
      const updateData: UpdateStopRequest = {
        address: 'New Address',
      };

      const response = await request(app)
        .put(`/api/trips/${testShareCode}/stops/${testStopId}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.address).toBe('New Address');
    });

    it('should update multiple fields at once', async () => {
      const updateData: UpdateStopRequest = {
        name: 'Completely Updated',
        latitude: 40.7650,
        longitude: -73.9900,
        address: 'Brand New Address',
      };

      const response = await request(app)
        .put(`/api/trips/${testShareCode}/stops/${testStopId}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toMatchObject({
        name: 'Completely Updated',
        latitude: 40.7650,
        longitude: -73.9900,
        address: 'Brand New Address',
      });
    });

    it('should return 404 for non-existent stop', async () => {
      const response = await request(app)
        .put(`/api/trips/${testShareCode}/stops/invalid-id`)
        .send({ name: 'Updated' })
        .expect(404);

      expect(response.body.success).toBe(false);
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await request(app)
        .put(`/api/trips/INVALID/stops/${testStopId}`)
        .send({ name: 'Updated' })
        .expect(404);

      expect(response.body.success).toBe(false);
    });

    it('should reject invalid coordinates', async () => {
      const response = await request(app)
        .put(`/api/trips/${testShareCode}/stops/${testStopId}`)
        .send({
          latitude: 200, // Invalid
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });

  describe('DELETE /api/trips/:shareCode/stops/:stopId', () => {
    let testStopId: string;

    beforeEach(async () => {
      const stopResponse = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Stop to Delete',
          latitude: 40.7580,
          longitude: -73.9855,
        });

      testStopId = stopResponse.body.data.id;
    });

    it('should delete a stop', async () => {
      await request(app)
        .delete(`/api/trips/${testShareCode}/stops/${testStopId}`)
        .expect(204);

      // Verify stop is deleted
      const stopsResponse = await request(app)
        .get(`/api/trips/${testShareCode}/stops`)
        .expect(200);

      expect(stopsResponse.body.data).toHaveLength(0);
    });

    it('should reorder remaining stops after deletion', async () => {
      // Add more stops
      const stop2 = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Stop 2',
          latitude: 40.7590,
          longitude: -73.9860,
        });

      const stop3 = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Stop 3',
          latitude: 40.7600,
          longitude: -73.9865,
        });

      // Delete the first stop
      await request(app)
        .delete(`/api/trips/${testShareCode}/stops/${testStopId}`)
        .expect(204);

      // Check that remaining stops are reordered
      const stopsResponse = await request(app)
        .get(`/api/trips/${testShareCode}/stops`)
        .expect(200);

      expect(stopsResponse.body.data).toHaveLength(2);
      expect(stopsResponse.body.data[0].order).toBe(0);
      expect(stopsResponse.body.data[1].order).toBe(1);
    });

    it('should return 404 for non-existent stop', async () => {
      const response = await request(app)
        .delete(`/api/trips/${testShareCode}/stops/invalid-id`)
        .expect(404);

      expect(response.body.success).toBe(false);
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await request(app)
        .delete(`/api/trips/INVALID/stops/${testStopId}`)
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });

  describe('PUT /api/trips/:shareCode/stops/reorder', () => {
    let stop1Id: string;
    let stop2Id: string;
    let stop3Id: string;

    beforeEach(async () => {
      // Add three stops
      const s1 = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Stop 1',
          latitude: 40.7580,
          longitude: -73.9855,
        });

      const s2 = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Stop 2',
          latitude: 40.7590,
          longitude: -73.9860,
        });

      const s3 = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Stop 3',
          latitude: 40.7600,
          longitude: -73.9865,
        });

      stop1Id = s1.body.data.id;
      stop2Id = s2.body.data.id;
      stop3Id = s3.body.data.id;
    });

    it('should reorder stops', async () => {
      const reorderData: ReorderStopsRequest = {
        stopIds: [stop3Id, stop1Id, stop2Id], // Reverse and shuffle
      };

      const response = await request(app)
        .put(`/api/trips/${testShareCode}/stops/reorder`)
        .send(reorderData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(3);
      
      // Check new order
      expect(response.body.data[0].id).toBe(stop3Id);
      expect(response.body.data[0].order).toBe(0);
      
      expect(response.body.data[1].id).toBe(stop1Id);
      expect(response.body.data[1].order).toBe(1);
      
      expect(response.body.data[2].id).toBe(stop2Id);
      expect(response.body.data[2].order).toBe(2);
    });

    it('should persist reordered stops', async () => {
      const reorderData: ReorderStopsRequest = {
        stopIds: [stop2Id, stop3Id, stop1Id],
      };

      await request(app)
        .put(`/api/trips/${testShareCode}/stops/reorder`)
        .send(reorderData)
        .expect(200);

      // Fetch stops again to verify persistence
      const response = await request(app)
        .get(`/api/trips/${testShareCode}/stops`)
        .expect(200);

      expect(response.body.data[0].id).toBe(stop2Id);
      expect(response.body.data[1].id).toBe(stop3Id);
      expect(response.body.data[2].id).toBe(stop1Id);
    });

    it('should reject reorder with extra stops', async () => {
      const reorderData: ReorderStopsRequest = {
        stopIds: [stop1Id, stop2Id, stop3Id, stop1Id], // Too many
      };

      const response = await request(app)
        .put(`/api/trips/${testShareCode}/stops/reorder`)
        .send(reorderData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should reject reorder with invalid stop IDs', async () => {
      const reorderData: ReorderStopsRequest = {
        stopIds: [stop1Id, stop2Id, 'invalid-id'],
      };

      const response = await request(app)
        .put(`/api/trips/${testShareCode}/stops/reorder`)
        .send(reorderData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should reject reorder with wrong number of stops', async () => {
      const reorderData: ReorderStopsRequest = {
        stopIds: [stop1Id, stop2Id], // Missing stop3
      };

      const response = await request(app)
        .put(`/api/trips/${testShareCode}/stops/reorder`)
        .send(reorderData)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should reject empty stop IDs array', async () => {
      const response = await request(app)
        .put(`/api/trips/${testShareCode}/stops/reorder`)
        .send({ stopIds: [] })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should return 404 for non-existent trip', async () => {
      const reorderData: ReorderStopsRequest = {
        stopIds: [stop1Id, stop2Id, stop3Id],
      };

      const response = await request(app)
        .put('/api/trips/INVALID/stops/reorder')
        .send(reorderData)
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });

  describe('Integration: Complete stop management workflow', () => {
    it('should handle complete stop lifecycle', async () => {
      // 1. Add stops
      const stop1 = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Coffee Shop',
          latitude: 40.7580,
          longitude: -73.9855,
        })
        .expect(201);

      const stop2 = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Park',
          latitude: 40.7590,
          longitude: -73.9860,
        })
        .expect(201);

      const stop3 = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'Restaurant',
          latitude: 40.7600,
          longitude: -73.9865,
        })
        .expect(201);

      // 2. Get all stops
      let stops = await request(app)
        .get(`/api/trips/${testShareCode}/stops`)
        .expect(200);

      expect(stops.body.data).toHaveLength(3);

      // 3. Update a stop
      await request(app)
        .put(`/api/trips/${testShareCode}/stops/${stop2.body.data.id}`)
        .send({ name: 'Central Park' })
        .expect(200);

      // 4. Reorder stops
      await request(app)
        .put(`/api/trips/${testShareCode}/stops/reorder`)
        .send({
          stopIds: [
            stop3.body.data.id,
            stop1.body.data.id,
            stop2.body.data.id,
          ],
        })
        .expect(200);

      // 5. Verify reordering
      stops = await request(app)
        .get(`/api/trips/${testShareCode}/stops`)
        .expect(200);

      expect(stops.body.data[0].name).toBe('Restaurant');
      expect(stops.body.data[1].name).toBe('Coffee Shop');
      expect(stops.body.data[2].name).toBe('Central Park');

      // 6. Delete a stop
      await request(app)
        .delete(`/api/trips/${testShareCode}/stops/${stop1.body.data.id}`)
        .expect(204);

      // 7. Verify deletion and reordering
      stops = await request(app)
        .get(`/api/trips/${testShareCode}/stops`)
        .expect(200);

      expect(stops.body.data).toHaveLength(2);
      expect(stops.body.data[0].order).toBe(0);
      expect(stops.body.data[1].order).toBe(1);
    });
  });
});

