import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import { createServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';
import dotenv from 'dotenv';

import routes from './routes';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { checkDatabaseHealth, disconnectDatabase } from './services/database';
import { initializeWebSocketService } from './services/websocketService';

// Load environment variables
dotenv.config();

const app = express();
const server = createServer(app);

// Socket.IO setup for real-time features
const io = new SocketIOServer(server, {
  cors: {
    origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
  },
});

// Middleware
app.use(helmet()); // Security headers
app.use(compression() as unknown as express.RequestHandler); // Gzip compression

// CORS configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
  credentials: true,
}));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging in development
if (process.env.NODE_ENV === 'development') {
  app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
  });
}

// Make Socket.IO available to routes
app.set('io', io);

// API routes
app.use('/api', routes);

// 404 handler
app.use(notFoundHandler);

// Global error handler (must be last)
app.use(errorHandler);

// Initialize WebSocket service
const wsService = initializeWebSocketService(io);

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log(`Client connected: ${socket.id}`);

  // Join trip room for real-time updates
  socket.on('join-trip', (shareCode: string) => {
    socket.join(`trip:${shareCode}`);
    console.log(`Client ${socket.id} joined trip: ${shareCode}`);
    
    // Notify others in the trip
    socket.to(`trip:${shareCode}`).emit('trip:joined', {
      participantCount: wsService.getTripParticipantCount(shareCode),
    });
  });

  // Leave trip room
  socket.on('leave-trip', (shareCode: string) => {
    socket.leave(`trip:${shareCode}`);
    console.log(`Client ${socket.id} left trip: ${shareCode}`);
  });

  socket.on('disconnect', () => {
    console.log(`Client disconnected: ${socket.id}`);
  });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  
  server.close(() => {
    console.log('HTTP server closed');
  });
  
  await disconnectDatabase();
  console.log('Database disconnected');
  
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, shutting down gracefully');
  
  server.close(() => {
    console.log('HTTP server closed');
  });
  
  await disconnectDatabase();
  console.log('Database disconnected');
  
  process.exit(0);
});

// Start server
const PORT = process.env.PORT || 3001;

async function startServer() {
  try {
    // Check database connection
    const dbHealthy = await checkDatabaseHealth();
    if (!dbHealthy) {
      console.error('Database health check failed. Please check your DATABASE_URL.');
      process.exit(1);
    }

    server.listen(PORT, () => {
      console.log(`🚀 Convooy API server running on port ${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🗄️  Database: Connected`);
      console.log(`🔗 API Base URL: http://localhost:${PORT}/api`);
      console.log(`💡 Health Check: http://localhost:${PORT}/api/health`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Export for testing
export { app, io };

// Start server if this file is run directly
if (require.main === module) {
  startServer();
}
