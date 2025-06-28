import { Router } from 'express';
import { clientManagementController } from '../controllers/clientManagementController';
import { requireRole } from '../middleware/auth';

const router = Router();

// Todas as rotas requerem autenticação e role de trainer
router.use(requireRole(['trainer', 'admin']));

// Rotas de gestão de clientes
router.get('/', clientManagementController.getClients);
router.get('/stats/financial', clientManagementController.getFinancialStats);
router.get('/:id', clientManagementController.getClient);
router.post('/', clientManagementController.addClient);
router.put('/:id', clientManagementController.updateClient);
router.delete('/:id', clientManagementController.removeClient);

export default router; 