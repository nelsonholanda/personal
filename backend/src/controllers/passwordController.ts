import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import passwordService from '../services/passwordService';
import jwt from 'jsonwebtoken';
// import awsSecretsManager from '../services/awsSecretsManager';

const prisma = new PrismaClient();

export const passwordController = {
  /**
   * Altera a senha do usuário logado
   */
  changePassword: async (req: Request, res: Response) => {
    try {
      const userId = req.user!.id;
      const { currentPassword, newPassword } = req.body;

      if (!currentPassword || !newPassword) {
        return res.status(400).json({
          success: false,
          error: 'Senha atual e nova senha são obrigatórias'
        });
      }

      // Busca o usuário
      const user = await prisma.user.findUnique({
        where: { id: userId }
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          error: 'Usuário não encontrado'
        });
      }

      // Verifica a senha atual
      const isCurrentPasswordValid = await passwordService.verifyPassword(
        currentPassword,
        user.passwordHash
      );

      if (!isCurrentPasswordValid) {
        return res.status(400).json({
          success: false,
          error: 'Senha atual incorreta'
        });
      }

      // Atualiza a senha
      await passwordService.updatePassword(userId, newPassword);

      res.json({
        success: true,
        message: 'Senha alterada com sucesso'
      });
    } catch (error: any) {
      console.error('Change password error:', error);
      res.status(400).json({
        success: false,
        error: error.message || 'Erro ao alterar senha'
      });
    }
  },

  /**
   * Solicita reset de senha
   */
  requestPasswordReset: async (req: Request, res: Response) => {
    try {
      const { email } = req.body;

      if (!email) {
        return res.status(400).json({
          success: false,
          error: 'Email é obrigatório'
        });
      }

      // Cria o token de reset
      const resetToken = await passwordService.createPasswordResetToken(email);

      if (!resetToken) {
        // Não revela se o email existe ou não
        return res.json({
          success: true,
          message: 'Se o email existir, você receberá um link para reset de senha'
        });
      }

      // TODO: Enviar email com o token
      // Por enquanto, retorna o token (apenas para desenvolvimento)
      if (process.env.NODE_ENV === 'development') {
        return res.json({
          success: true,
          message: 'Token de reset criado com sucesso',
          resetToken // Remover em produção
        });
      }

      res.json({
        success: true,
        message: 'Se o email existir, você receberá um link para reset de senha'
      });
    } catch (error) {
      console.error('Request password reset error:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao solicitar reset de senha'
      });
    }
  },

  /**
   * Reseta a senha usando token
   */
  resetPassword: async (req: Request, res: Response) => {
    try {
      const { token, newPassword } = req.body;

      if (!token || !newPassword) {
        return res.status(400).json({
          success: false,
          error: 'Token e nova senha são obrigatórios'
        });
      }

      // Reseta a senha
      const success = await passwordService.resetPasswordWithToken(token, newPassword);

      if (!success) {
        return res.status(400).json({
          success: false,
          error: 'Token inválido ou expirado'
        });
      }

      res.json({
        success: true,
        message: 'Senha redefinida com sucesso'
      });
    } catch (error: any) {
      console.error('Reset password error:', error);
      res.status(400).json({
        success: false,
        error: error.message || 'Erro ao redefinir senha'
      });
    }
  },

  /**
   * Altera senha de outro usuário (apenas admin)
   */
  changeUserPassword: async (req: Request, res: Response) => {
    try {
      const adminId = req.user!.id;
      const { userId, newPassword, forceChange = false } = req.body;

      // Verifica se é admin
      const admin = await prisma.user.findUnique({
        where: { id: adminId }
      });

      if (!admin || admin.role !== 'admin') {
        return res.status(403).json({
          success: false,
          error: 'Acesso negado. Apenas administradores podem alterar senhas de outros usuários'
        });
      }

      if (!userId || !newPassword) {
        return res.status(400).json({
          success: false,
          error: 'ID do usuário e nova senha são obrigatórios'
        });
      }

      // Verifica se o usuário existe
      const user = await prisma.user.findUnique({
        where: { id: userId }
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          error: 'Usuário não encontrado'
        });
      }

      // Atualiza a senha
      await passwordService.updatePassword(userId, newPassword);

      // Se forceChange for true, força mudança na próxima sessão
      if (forceChange) {
        await passwordService.forcePasswordChange(userId);
      }

      res.json({
        success: true,
        message: `Senha do usuário ${user.name} alterada com sucesso`
      });
    } catch (error: any) {
      console.error('Change user password error:', error);
      res.status(400).json({
        success: false,
        error: error.message || 'Erro ao alterar senha do usuário'
      });
    }
  },

  /**
   * Gera uma senha segura aleatória
   */
  generateSecurePassword: async (req: Request, res: Response) => {
    try {
      const { length = 12 } = req.body;

      const securePassword = passwordService.generateSecurePassword(length);

      res.json({
        success: true,
        data: {
          password: securePassword,
          length: securePassword.length
        }
      });
    } catch (error) {
      console.error('Generate secure password error:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao gerar senha segura'
      });
    }
  },

  /**
   * Verifica se a senha precisa ser alterada
   */
  checkPasswordChangeRequired: async (req: Request, res: Response) => {
    try {
      const userId = req.user!.id;

      const isRequired = await passwordService.isPasswordChangeRequired(userId);

      res.json({
        success: true,
        data: {
          passwordChangeRequired: isRequired
        }
      });
    } catch (error) {
      console.error('Check password change required error:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao verificar necessidade de mudança de senha'
      });
    }
  },

  /**
   * Lista histórico de senhas (apenas admin)
   */
  getPasswordHistory: async (req: Request, res: Response) => {
    try {
      const adminId = req.user!.id;
      const { userId } = req.params;

      // Verifica se é admin
      const admin = await prisma.user.findUnique({
        where: { id: adminId }
      });

      if (!admin || admin.role !== 'admin') {
        return res.status(403).json({
          success: false,
          error: 'Acesso negado. Apenas administradores podem visualizar histórico de senhas'
        });
      }

      const history = await prisma.passwordHistory.findMany({
        where: { userId: parseInt(userId) },
        orderBy: { changedAt: 'desc' },
        select: {
          id: true,
          changedAt: true,
          // Não retorna o hash da senha por segurança
        }
      });

      res.json({
        success: true,
        data: {
          history,
          count: history.length
        }
      });
    } catch (error) {
      console.error('Get password history error:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao buscar histórico de senhas'
      });
    }
  },

  /**
   * Força mudança de senha para um usuário (apenas admin)
   */
  forcePasswordChange: async (req: Request, res: Response) => {
    try {
      const adminId = req.user!.id;
      const { userId } = req.params;

      // Verifica se é admin
      const admin = await prisma.user.findUnique({
        where: { id: adminId }
      });

      if (!admin || admin.role !== 'admin') {
        return res.status(403).json({
          success: false,
          error: 'Acesso negado. Apenas administradores podem forçar mudança de senha'
        });
      }

      // Verifica se o usuário existe
      const user = await prisma.user.findUnique({
        where: { id: parseInt(userId) }
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          error: 'Usuário não encontrado'
        });
      }

      // Força mudança de senha
      await passwordService.forcePasswordChange(parseInt(userId));

      res.json({
        success: true,
        message: `Usuário ${user.name} será obrigado a alterar a senha na próxima sessão`
      });
    } catch (error) {
      console.error('Force password change error:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao forçar mudança de senha'
      });
    }
  },

  /**
   * Limpa tokens de reset expirados (cron job)
   */
  cleanupExpiredTokens: async (req: Request, res: Response) => {
    try {
      await passwordService.cleanupExpiredResetTokens();

      res.json({
        success: true,
        message: 'Tokens expirados limpos com sucesso'
      });
    } catch (error) {
      console.error('Cleanup expired tokens error:', error);
      res.status(500).json({
        success: false,
        error: 'Erro ao limpar tokens expirados'
      });
    }
  }
}; 