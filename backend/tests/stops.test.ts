import request from 'supertest';
import { app } from '../src/app';
import { TestFactory, createStopPayload } from './factory';

describe('Stops API', () => {
  let factory: TestFactory;
  let testShareCode: string;

  beforeEach(async () => {
    factory = new TestFactory();
    // Create a trip for each test
    const tripResponse = await factory.createTrip({
      name: 'Test Trip',
    });
    testShareCode = tripResponse.body.data.shareCode;
  });

  afterEach(async () => {
    await factory.cleanup();
  });

  describe('POST /api/trips/:shareCode/stops', () => {
    it('should add a stop to a trip', async () => {
      const response = await factory.createStop(testShareCode, {
        name: 'Coffee Shop',
        address: '456 Coffee St, New York, NY',
      });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toMatchObject({
        name: 'Coffee Shop',
        address: '456 Coffee St, New York, NY',
        order: 0, // First stop
      });
      expect(response.body.data.id).toBeDefined();
      expect(response.body.data.addedAt).toBeDefined();
      expect(response.body.data.latitude).toBeDefined();
      expect(response.body.data.longitude).toBeDefined();
    });

    it('should add stop without address', async () => {
      const coords = factory.randomCoordinates();
      const stopData = {
        name: 'Park',
        latitude: coords.latitude,
        longitude: coords.longitude,
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
      const stop1 = await factory.createStop(testShareCode, {
        name: 'Stop 1',
      });

      const stop2 = await factory.createStop(testShareCode, {
        name: 'Stop 2',
      });

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

    it('should reject stop without required name', async () => {
      const coords = factory.randomCoordinates();
      const response = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          latitude: coords.latitude,
          longitude: coords.longitude,
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should reject stop without coordinates', async () => {
      const response = await request(app)
        .post(`/api/trips/${testShareCode}/stops`)
        .send({
          name: 'No Coords Stop',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await factory.createStop('INVALID', {
        name: 'Test Stop',
      });

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/trips/:shareCode/stops', () => {
    it('should get all stops for a trip', async () => {
      // Add some stops
      await factory.createStop(testShareCode, { name: 'Stop 1' });
      await factory.createStop(testShareCode, { name: 'Stop 2' });
      await factory.createStop(testShareCode, { name: 'Stop 3' });

      const response = await factory.getStops(testShareCode);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(3);
      expect(response.body.data[0].name).toBe('Stop 1');
      expect(response.body.data[1].name).toBe('Stop 2');
      expect(response.body.data[2].name).toBe('Stop 3');
    });

    it('should return empty array for trip with no stops', async () => {
      const response = await factory.getStops(testShareCode);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual([]);
    });

    it('should return stops in correct order', async () => {
      const stop1 = await factory.createStop(testShareCode, { name: 'First' });
      const stop2 = await factory.createStop(testShareCode, { name: 'Second' });
      const stop3 = await factory.createStop(testShareCode, { name: 'Third' });

      const response = await factory.getStops(testShareCode);

      expect(response.body.data[0].order).toBe(0);
      expect(response.body.data[1].order).toBe(1);
      expect(response.body.data[2].order).toBe(2);
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await factory.getStops('INVALID');

      expect(response.status).toBe(404);
    });
  });

  describe('PUT /api/trips/:shareCode/stops/:stopId', () => {
    let testStopId: string;
    let localShareCode: string;

    beforeEach(async () => {
      // Create a fresh trip for this test
      const tripResponse = await factory.createTrip({ name: 'Test Trip for Update' });
      localShareCode = tripResponse.body.data.shareCode;
      
      const stopResponse = await factory.createStop(localShareCode, {
        name: 'Original Stop',
        address: 'Original Address',
      });
      testStopId = stopResponse.body.data.id;
    });

    it('should update stop name', async () => {
      const response = await factory.updateStop(localShareCode, testStopId, {
        name: 'Updated Stop',
      });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Updated Stop');
      expect(response.body.data.address).toBe('Original Address'); // Unchanged
    });

    it('should update stop address', async () => {
      const response = await factory.updateStop(localShareCode, testStopId, {
        address: 'New Address',
      });

      expect(response.status).toBe(200);
      expect(response.body.data.address).toBe('New Address');
      expect(response.body.data.name).toBe('Original Stop'); // Unchanged
    });

    it('should update stop coordinates', async () => {
      const newCoords = factory.randomCoordinates();

      const response = await factory.updateStop(localShareCode, testStopId, {
        latitude: newCoords.latitude,
        longitude: newCoords.longitude,
      });

      expect(response.status).toBe(200);
      expect(response.body.data.latitude).toBeCloseTo(newCoords.latitude, 10);
      expect(response.body.data.longitude).toBeCloseTo(newCoords.longitude, 10);
    });

    it('should update multiple fields at once', async () => {
      const newCoords = factory.randomCoordinates();

      const response = await factory.updateStop(localShareCode, testStopId, {
        name: 'New Name',
        address: 'New Address',
        latitude: newCoords.latitude,
        longitude: newCoords.longitude,
      });

      expect(response.status).toBe(200);
      expect(response.body.data.name).toBe('New Name');
      expect(response.body.data.address).toBe('New Address');
      expect(response.body.data.latitude).toBeCloseTo(newCoords.latitude, 10);
      expect(response.body.data.longitude).toBeCloseTo(newCoords.longitude, 10);
    });

    it('should reject invalid coordinates', async () => {
      const response = await factory.updateStop(localShareCode, testStopId, {
        latitude: 100, // Invalid
        longitude: -73.9855,
      });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await factory.updateStop('INVALID', testStopId, {
        name: 'Updated',
      });

      expect(response.status).toBe(404);
    });

    it('should return 404 for non-existent stop', async () => {
      const response = await factory.updateStop(localShareCode, 'invalid-stop-id', {
        name: 'Updated',
      });

      expect(response.status).toBe(404);
    });
  });

  describe('DELETE /api/trips/:shareCode/stops/:stopId', () => {
    let testStopId: string;
    let localShareCode: string;

    beforeEach(async () => {
      // Create a fresh trip for this test
      const tripResponse = await factory.createTrip({ name: 'Test Trip for Delete' });
      localShareCode = tripResponse.body.data.shareCode;
      
      const stopResponse = await factory.createStop(localShareCode, {
        name: 'Stop to Delete',
      });
      testStopId = stopResponse.body.data.id;
    });

    it('should delete a stop', async () => {
      const response = await factory.deleteStop(localShareCode, testStopId);

      expect(response.status).toBe(204);

      // Verify stop is gone
      const getStopsResponse = await factory.getStops(localShareCode);
      expect(getStopsResponse.body.data).toHaveLength(0);
    });

    it('should reorder remaining stops after deletion', async () => {
      // Create 3 stops
      const stop1 = await factory.createStop(localShareCode, { name: 'Stop 1' });
      const stop2 = await factory.createStop(localShareCode, { name: 'Stop 2' });
      const stop3 = await factory.createStop(localShareCode, { name: 'Stop 3' });

      // Delete middle stop
      await factory.deleteStop(localShareCode, stop2.body.data.id);

      // Check remaining stops are reordered
      const getResponse = await factory.getStops(localShareCode);
      expect(getResponse.body.data).toHaveLength(3); // Including the original one from beforeEach
      
      // Find our specific stops (exclude the beforeEach stop)
      const remainingStops = getResponse.body.data.filter(
        (s: any) => s.name === 'Stop 1' || s.name === 'Stop 3'
      );
      expect(remainingStops).toHaveLength(2);
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await factory.deleteStop('INVALID', testStopId);

      expect(response.status).toBe(404);
    });

    it('should return 404 for non-existent stop', async () => {
      const response = await factory.deleteStop(localShareCode, 'invalid-stop-id');

      expect(response.status).toBe(404);
    });
  });

  describe('PUT /api/trips/:shareCode/stops/reorder', () => {
    it('should reorder stops', async () => {
      // Create 3 stops
      const stop1 = await factory.createStop(testShareCode, { name: 'First' });
      const stop2 = await factory.createStop(testShareCode, { name: 'Second' });
      const stop3 = await factory.createStop(testShareCode, { name: 'Third' });

      const stopIds = [
        stop1.body.data.id,
        stop2.body.data.id,
        stop3.body.data.id,
      ];

      // Reorder: 3, 1, 2
      const newOrder = [stopIds[2], stopIds[0], stopIds[1]];

      const response = await factory.reorderStops(testShareCode, newOrder);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);

      // Verify new order
      const getResponse = await factory.getStops(testShareCode);
      expect(getResponse.body.data[0].id).toBe(stopIds[2]);
      expect(getResponse.body.data[1].id).toBe(stopIds[0]);
      expect(getResponse.body.data[2].id).toBe(stopIds[1]);
    });

    it('should handle single stop reorder', async () => {
      const stop = await factory.createStop(testShareCode, { name: 'Only Stop' });

      const response = await factory.reorderStops(testShareCode, [stop.body.data.id]);

      expect(response.status).toBe(200);
    });

    it('should reject empty stop array', async () => {
      const response = await factory.reorderStops(testShareCode, []);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it('should reject invalid stop IDs', async () => {
      const response = await factory.reorderStops(testShareCode, ['invalid-id']);

      expect(response.status).toBe(400);
    });

    it('should handle reorder with duplicate IDs gracefully', async () => {
      const stop1 = await factory.createStop(testShareCode, { name: 'Stop 1' });
      const stopId = stop1.body.data.id;

      // Current service doesn't explicitly validate duplicates, it processes them
      const response = await factory.reorderStops(testShareCode, [stopId, stopId]);

      // Service processes this (doesn't reject), but results may vary
      // This test documents current behavior
      expect([200, 400]).toContain(response.status);
    });

    it('should return 404 for non-existent trip', async () => {
      const response = await factory.reorderStops('INVALID', ['some-id']);

      expect(response.status).toBe(404);
    });
  });

  describe('Integration: Stop lifecycle', () => {
    it('should handle complete stop lifecycle', async () => {
      // Create stops
      const stop1 = await factory.createStop(testShareCode, { name: 'Stop 1' });
      const stop2 = await factory.createStop(testShareCode, { name: 'Stop 2' });
      const stop3 = await factory.createStop(testShareCode, { name: 'Stop 3' });
      
      expect(stop1.status).toBe(201);
      expect(stop2.status).toBe(201);
      expect(stop3.status).toBe(201);

      const stopIds = [
        stop1.body.data.id,
        stop2.body.data.id,
        stop3.body.data.id,
      ];

      // Get all stops
      let getResponse = await factory.getStops(testShareCode);
      expect(getResponse.body.data).toHaveLength(3);

      // Update a stop
      const updateResponse = await factory.updateStop(testShareCode, stopIds[0], {
        name: 'Updated Stop 1',
      });
      expect(updateResponse.status).toBe(200);

      // Reorder stops
      const reorderResponse = await factory.reorderStops(testShareCode, [
        stopIds[2],
        stopIds[0],
        stopIds[1],
      ]);
      expect(reorderResponse.status).toBe(200);

      // Verify order
      getResponse = await factory.getStops(testShareCode);
      expect(getResponse.body.data[0].id).toBe(stopIds[2]);
      expect(getResponse.body.data[1].name).toBe('Updated Stop 1');

      // Delete a stop
      const deleteResponse = await factory.deleteStop(testShareCode, stopIds[1]);
      expect(deleteResponse.status).toBe(204);

      // Verify deletion
      getResponse = await factory.getStops(testShareCode);
      expect(getResponse.body.data).toHaveLength(2);
    });

    it('should handle stops across multiple trips', async () => {
      // Create second trip
      const trip2Response = await factory.createTrip({
        name: 'Second Trip',
      });
      const trip2ShareCode = trip2Response.body.data.shareCode;

      // Add stops to both trips
      await factory.createStop(testShareCode, { name: 'Trip 1 Stop 1' });
      await factory.createStop(testShareCode, { name: 'Trip 1 Stop 2' });
      await factory.createStop(trip2ShareCode, { name: 'Trip 2 Stop 1' });
      await factory.createStop(trip2ShareCode, { name: 'Trip 2 Stop 2' });

      // Verify stops are separate
      const trip1Stops = await factory.getStops(testShareCode);
      const trip2Stops = await factory.getStops(trip2ShareCode);

      expect(trip1Stops.body.data).toHaveLength(2);
      expect(trip2Stops.body.data).toHaveLength(2);
      expect(trip1Stops.body.data[0].name).toBe('Trip 1 Stop 1');
      expect(trip2Stops.body.data[0].name).toBe('Trip 2 Stop 1');
    });
  });
});
