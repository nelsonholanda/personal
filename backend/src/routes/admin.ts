import { Router } from 'express';
import { adminController } from '../controllers/adminController';
import { requireRole } from '../middleware/auth';

const router = Router();

router.use(requireRole(['admin']));

router.get('/trainers', adminController.listTrainers);
router.post('/trainers', adminController.createTrainer);
router.put('/trainers/:id', adminController.updateTrainer);
router.patch('/trainers/:id/activate', adminController.activateTrainer);
router.post('/trainers/:id/reset-password', adminController.resetTrainerPassword);
router.delete('/trainers/:id', adminController.deleteTrainer);

router.get('/users', adminController.listUsers);
router.patch('/users/:id/role', adminController.updateUserRole);

router.get('/stats', adminController.getStats);

export default router; 