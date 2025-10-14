import { Server as SocketIOServer } from 'socket.io';
import { TripResponse, StopResponse, WebSocketEvents } from '../models/types';

export class WebSocketService {
  private io: SocketIOServer;

  constructor(io: SocketIOServer) {
    this.io = io;
  }

  /**
   * Emit trip updated event to all clients in the trip room
   */
  emitTripUpdated(shareCode: string, trip: TripResponse): void {
    this.io.to(`trip:${shareCode}`).emit('trip:updated', trip);
  }

  /**
   * Emit stop added event to all clients in the trip room
   */
  emitStopAdded(shareCode: string, stop: StopResponse): void {
    this.io.to(`trip:${shareCode}`).emit('stop:added', {
      tripId: shareCode,
      stop,
    });
  }

  /**
   * Emit stop removed event to all clients in the trip room
   */
  emitStopRemoved(shareCode: string, stopId: string): void {
    this.io.to(`trip:${shareCode}`).emit('stop:removed', {
      tripId: shareCode,
      stopId,
    });
  }

  /**
   * Emit stop updated event to all clients in the trip room
   */
  emitStopUpdated(shareCode: string, stop: StopResponse): void {
    this.io.to(`trip:${shareCode}`).emit('stop:updated', {
      tripId: shareCode,
      stop,
    });
  }

  /**
   * Emit stops reordered event to all clients in the trip room
   */
  emitStopsReordered(shareCode: string, stops: StopResponse[]): void {
    this.io.to(`trip:${shareCode}`).emit('stops:reordered', {
      tripId: shareCode,
      stops,
    });
  }

  /**
   * Get the number of participants in a trip room
   */
  getTripParticipantCount(shareCode: string): number {
    const room = this.io.sockets.adapter.rooms.get(`trip:${shareCode}`);
    return room?.size || 0;
  }

  /**
   * Get all active trip rooms
   */
  getActiveTripRooms(): string[] {
    const rooms: string[] = [];
    
    for (const [roomName] of this.io.sockets.adapter.rooms) {
      if (roomName.startsWith('trip:')) {
        rooms.push(roomName.replace('trip:', ''));
      }
    }
    
    return rooms;
  }

  /**
   * Broadcast a message to all clients in a trip room
   */
  broadcastToTrip(shareCode: string, event: string, data: any): void {
    this.io.to(`trip:${shareCode}`).emit(event, data);
  }

  /**
   * Get Socket.IO server instance for advanced usage
   */
  getIO(): SocketIOServer {
    return this.io;
  }
}

// Singleton instance
let websocketService: WebSocketService | null = null;

export function initializeWebSocketService(io: SocketIOServer): WebSocketService {
  websocketService = new WebSocketService(io);
  return websocketService;
}

export function getWebSocketService(): WebSocketService {
  if (!websocketService) {
    throw new Error('WebSocket service not initialized. Call initializeWebSocketService first.');
  }
  return websocketService;
}
