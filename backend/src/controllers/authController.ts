import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import databaseService from '../services/databaseService';

interface RegisterRequest {
  name: string;
  email: string;
  password: string;
  role: 'trainer' | 'client' | 'admin';
  phone?: string;
  birthDate?: string;
  gender?: 'male' | 'female' | 'other';
  height?: number;
  weight?: number;
}

interface LoginRequest {
  email?: string;
  name?: string;
  password: string;
}

export const authController = {
  // Registrar usuário
  register: async (req: Request, res: Response) => {
    try {
      const { name, email, password, role, phone, birthDate, gender, height, weight }: RegisterRequest = req.body;

      const prisma = await databaseService.getPrismaClient();

      // Verificar se o usuário já existe
      const existingUser = await prisma.user.findUnique({
        where: { email }
      });

      if (existingUser) {
        return res.status(400).json({
          success: false,
          error: 'Usuário já existe'
        });
      }

      // Hash da senha
      const saltRounds = 12;
      const passwordHash = await bcrypt.hash(password, saltRounds);

      // Criar usuário
      const user = await prisma.user.create({
        data: {
          name,
          email,
          passwordHash,
          role,
          phone,
          birthDate: birthDate ? new Date(birthDate) : undefined,
          gender,
          height: height ? parseFloat(height.toString()) : undefined,
          weight: weight ? parseFloat(weight.toString()) : undefined
        }
      });

      // Gerar token JWT
      const token = jwt.sign(
        { id: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET || 'your-secret-key',
        { expiresIn: '24h' }
      );

      res.status(201).json({
        success: true,
        data: {
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role
          },
          token
        }
      });
    } catch (error) {
      console.error('Register error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Login
  login: async (req: Request, res: Response) => {
    try {
      const { email, name, password } = req.body;

      const prisma = await databaseService.getPrismaClient();

      // Buscar usuário por email ou nome
      let user;
      if (email) {
        user = await prisma.user.findUnique({
          where: { email }
        });
      } else if (name) {
        user = await prisma.user.findFirst({
          where: { name }
        });
      } else {
        return res.status(400).json({
          success: false,
          error: 'Email ou nome de usuário é obrigatório'
        });
      }

      if (!user) {
        return res.status(401).json({
          success: false,
          error: 'Credenciais inválidas'
        });
      }

      // Verificar senha
      const isValidPassword = await bcrypt.compare(password, user.passwordHash);
      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          error: 'Credenciais inválidas'
        });
      }

      // Verificar se o usuário está ativo
      if (!user.isActive) {
        return res.status(401).json({
          success: false,
          error: 'Conta desativada'
        });
      }

      // Gerar token JWT
      const token = jwt.sign(
        { id: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET || 'your-secret-key',
        { expiresIn: '24h' }
      );

      res.json({
        success: true,
        data: {
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role
          },
          token
        }
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Obter perfil do usuário
  getProfile: async (req: Request, res: Response) => {
    try {
      const userId = req.user!.id;

      const prisma = await databaseService.getPrismaClient();

      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
          phone: true,
          birthDate: true,
          gender: true,
          height: true,
          weight: true,
          profileImageUrl: true,
          isActive: true,
          createdAt: true
        }
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          error: 'Usuário não encontrado'
        });
      }

      res.json({
        success: true,
        data: user
      });
    } catch (error) {
      console.error('Get profile error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Get current user
  getMe: async (req: Request, res: Response) => {
    try {
      const prisma = await databaseService.getPrismaClient();
      
      const user = await prisma.user.findUnique({
        where: { id: req.user!.id },
        include: {
          trainerProfile: true,
          clientProfile: true
        }
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          error: 'Usuário não encontrado'
        });
      }

      // Remove password from response
      const { passwordHash, ...userWithoutPassword } = user;

      return res.json({
        success: true,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          phone: user.phone,
          specialization: user.trainerProfile?.specialization,
          bio: user.trainerProfile?.bio
        }
      });
    } catch (error) {
      console.error('Get me error:', error);
      return res.status(500).json({
        success: false,
        error: 'Erro interno do servidor'
      });
    }
  },

  // Change password
  changePassword: async (req: Request, res: Response) => {
    try {
      const { currentPassword, newPassword } = req.body;
      const userId = req.user!.id;

      const prisma = await databaseService.getPrismaClient();

      // Get user with password
      const user = await prisma.user.findUnique({
        where: { id: userId }
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          error: 'Usuário não encontrado'
        });
      }

      // Verify current password
      const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.passwordHash);
      if (!isCurrentPasswordValid) {
        return res.status(400).json({
          success: false,
          error: 'Senha atual incorreta'
        });
      }

      // Hash new password
      const salt = await bcrypt.genSalt(12);
      const newPasswordHash = await bcrypt.hash(newPassword, salt);

      // Update password
      await prisma.user.update({
        where: { id: userId },
        data: {
          passwordHash: newPasswordHash,
          passwordChangedAt: new Date()
        }
      });

      return res.json({
        success: true,
        message: 'Senha alterada com sucesso'
      });
    } catch (error) {
      console.error('Change password error:', error);
      return res.status(500).json({
        success: false,
        error: 'Erro interno do servidor'
      });
    }
  },

  // Logout (client-side token removal)
  logout: async (req: Request, res: Response) => {
    return res.json({
      success: true,
      message: 'Logout realizado com sucesso'
    });
  },

  // Refresh token
  refreshToken: async (req: Request, res: Response) => {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        return res.status(400).json({
          success: false,
          error: 'Refresh token é obrigatório'
        });
      }

      const prisma = await databaseService.getPrismaClient();

      // Verificar o refresh token
      const decoded = jwt.verify(
        refreshToken,
        process.env.JWT_REFRESH_TOKEN_SECRET || 'nh-personal-refresh-token-secret-2024'
      ) as any;

      // Buscar o usuário
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        select: {
          id: true,
          email: true,
          role: true,
          isActive: true
        }
      });

      if (!user || !user.isActive) {
        return res.status(401).json({
          success: false,
          error: 'Token inválido ou usuário inativo'
        });
      }

      // Gerar novo access token
      const newAccessToken = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_ACCESS_TOKEN_SECRET || 'nh-personal-access-token-secret-2024',
        { expiresIn: '24h' }
      );

      return res.json({
        success: true,
        data: {
          accessToken: newAccessToken,
          user: {
            id: user.id,
            email: user.email,
            role: user.role
          }
        }
      });
    } catch (error) {
      console.error('Refresh token error:', error);
      return res.status(401).json({
        success: false,
        error: 'Token inválido'
      });
    }
  }
}; 