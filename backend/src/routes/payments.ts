import { Router } from 'express';
import { paymentController } from '../controllers/paymentController';
import { requireRole } from '../middleware/auth';

const router = Router();

// Todas as rotas requerem autenticação e role de trainer
router.use(requireRole(['trainer', 'admin']));

// Rotas de pagamentos
router.get('/', paymentController.getPayments);
router.get('/methods', paymentController.getPaymentMethods);
router.get('/plans', paymentController.getPaymentPlans);
router.get('/:id', paymentController.getPayment);
router.post('/', paymentController.createPayment);
router.put('/:id', paymentController.updatePayment);
router.put('/:id/mark-paid', paymentController.markAsPaid);

export default router; 