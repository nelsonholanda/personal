import express from 'express';
import { passwordController } from '../controllers/passwordController';
import { authenticateToken } from '../middleware/auth';
import { adminOnly } from '../middleware/adminAuth';

const router = express.Router();

// Rotas públicas (não requerem autenticação)
router.post('/request-reset', passwordController.requestPasswordReset);
router.post('/reset', passwordController.resetPassword);

// Rotas que requerem autenticação
router.use(authenticateToken);

// Alterar própria senha
router.post('/change', passwordController.changePassword);

// Verificar se precisa alterar senha
router.get('/check-change-required', passwordController.checkPasswordChangeRequired);

// Gerar senha segura
router.post('/generate', passwordController.generateSecurePassword);

// Rotas apenas para administradores
router.use(adminOnly);

// Alterar senha de outro usuário
router.post('/change-user', passwordController.changeUserPassword);

// Forçar mudança de senha
router.post('/force-change/:userId', passwordController.forcePasswordChange);

// Histórico de senhas
router.get('/history/:userId', passwordController.getPasswordHistory);

// Limpar tokens expirados (cron job)
router.post('/cleanup-tokens', passwordController.cleanupExpiredTokens);

export default router; 