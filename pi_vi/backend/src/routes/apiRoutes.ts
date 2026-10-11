import { Router } from 'express';
import { createDevice, deleteDevice, getDashboard, getDevice, listDevices, updateDevice } from '../controllers/deviceController';
import { authenticateToken } from '../middlewares/authMiddleware';

export const apiRouter = Router();

apiRouter.get('/dashboard', authenticateToken, getDashboard);
apiRouter.get('/devices', authenticateToken, listDevices);
apiRouter.post('/devices', authenticateToken, createDevice);
apiRouter.get('/devices/:id', authenticateToken, getDevice);
apiRouter.patch('/devices/:id', authenticateToken, updateDevice);
apiRouter.delete('/devices/:id', authenticateToken, deleteDevice);