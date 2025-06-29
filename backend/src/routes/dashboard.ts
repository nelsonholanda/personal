import { Router } from 'express';
import { dashboardController } from '../controllers/dashboardController';
import { authMiddleware } from '../middleware/auth';

const router = Router();

// Todas as rotas do dashboard requerem autenticação
router.use(authMiddleware);

router.get('/stats', dashboardController.getStats);
router.get('/recent-activity', dashboardController.getRecentActivity);
router.get('/upcoming-sessions', dashboardController.getUpcomingSessions);

export default router; 