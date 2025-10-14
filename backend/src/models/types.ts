import { z } from 'zod';

// Location schema (for destinations and coordinates)
export const LocationSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  address: z.string().optional(),
});

export type Location = z.infer<typeof LocationSchema>;

// Stop schemas
export const CreateStopSchema = z.object({
  name: z.string().min(1, 'Stop name is required'),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  address: z.string().optional(),
});

export const UpdateStopSchema = CreateStopSchema.partial();

export const ReorderStopsSchema = z.object({
  stopIds: z.array(z.string()).min(1, 'At least one stop ID is required'),
});

export type CreateStopRequest = z.infer<typeof CreateStopSchema>;
export type UpdateStopRequest = z.infer<typeof UpdateStopSchema>;
export type ReorderStopsRequest = z.infer<typeof ReorderStopsSchema>;

// Trip schemas
export const CreateTripSchema = z.object({
  name: z.string().optional(),
  destination: LocationSchema,
});

export const UpdateTripSchema = z.object({
  name: z.string().optional(),
  destination: LocationSchema.optional(),
});

export type CreateTripRequest = z.infer<typeof CreateTripSchema>;
export type UpdateTripRequest = z.infer<typeof UpdateTripSchema>;

// Response types
export interface StopResponse {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  address?: string;
  order: number;
  addedAt: string;
}

export interface TripResponse {
  id: string;
  shareCode: string;
  name?: string;
  destination: Location;
  stops: StopResponse[];
  createdAt: string;
  updatedAt: string;
}

export interface ShareResponse {
  shareCode: string;
  shareUrl: string;
  qrCodeUrl?: string;
}

// WebSocket event types
export interface WebSocketEvents {
  'trip:updated': TripResponse;
  'stop:added': { tripId: string; stop: StopResponse };
  'stop:removed': { tripId: string; stopId: string };
  'stop:updated': { tripId: string; stop: StopResponse };
  'stops:reordered': { tripId: string; stops: StopResponse[] };
  'trip:joined': { tripId: string; participantCount: number };
}

// Error types
export interface ApiError {
  error: string;
  message: string;
  statusCode: number;
  details?: unknown;
}

// Share code validation
export const ShareCodeSchema = z.string()
  .min(6, 'Share code must be at least 6 characters')
  .max(8, 'Share code must be at most 8 characters')
  .regex(/^[A-Z0-9]+$/, 'Share code must contain only uppercase letters and numbers');

export type ShareCode = z.infer<typeof ShareCodeSchema>;
