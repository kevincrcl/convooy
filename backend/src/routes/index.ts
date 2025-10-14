import { Router } from 'express';
import tripRoutes from './trips';
import stopRoutes from './stops';

const router = Router();

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Convooy API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// API routes
router.use('/trips', tripRoutes);
router.use('/trips', stopRoutes); // Stop routes are nested under trips

export default router;
