import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import databaseService from '../services/databaseService';

const prisma = databaseService.getPrismaClient();

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
  email: string;
  password: string;
}

export const authController = {
  // Register new user
  register: async (req: Request, res: Response) => {
    try {
      const { name, email, password, role, phone, birthDate, gender, height, weight }: RegisterRequest = req.body;

      // Check if user already exists
      const existingUser = await prisma.user.findUnique({
        where: { email }
      });

      if (existingUser) {
        return res.status(400).json({
          success: false,
          error: 'Usuário já existe com este email'
        });
      }

      // Hash password
      const salt = await bcrypt.genSalt(12);
      const passwordHash = await bcrypt.hash(password, salt);

      // Create user
      const user = await prisma.user.create({
        data: {
          name,
          email,
          passwordHash,
          role,
          phone,
          birthDate: birthDate ? new Date(birthDate) : null,
          gender,
          height: height ? parseFloat(height.toString()) : null,
          weight: weight ? parseFloat(weight.toString()) : null,
          isActive: true,
          passwordChangedAt: new Date()
        },
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
          isActive: true,
          createdAt: true
        }
      });

      // Create profile based on role
      if (role === 'trainer') {
        await prisma.trainerProfile.create({
          data: {
            userId: user.id,
            specialization: '',
            experienceYears: 0,
            hourlyRate: 0
          }
        });
      } else if (role === 'client') {
        await prisma.clientProfile.create({
          data: {
            userId: user.id,
            fitnessGoals: '',
            medicalConditions: ''
          }
        });
      }

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_ACCESS_TOKEN_SECRET || 'nh-personal-access-token-secret-2024',
        { expiresIn: '24h' }
      );

      res.status(201).json({
        success: true,
        data: {
          user,
          token
        }
      });
    } catch (error) {
      console.error('Register error:', error);
      return res.status(500).json({
        success: false,
        error: 'Erro interno do servidor'
      });
    }
  },

  // Login user
  login: async (req: Request, res: Response) => {
    try {
      const { email, password }: LoginRequest = req.body;

      // Find user
      const user = await prisma.user.findUnique({
        where: { email },
        include: {
          trainerProfile: true,
          clientProfile: true
        }
      });

      if (!user) {
        return res.status(400).json({
          success: false,
          error: 'Credenciais inválidas'
        });
      }

      // Check if user is active
      if (!user.isActive) {
        return res.status(400).json({
          success: false,
          error: 'Conta desativada'
        });
      }

      // Verify password
      const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
      if (!isPasswordValid) {
        return res.status(400).json({
          success: false,
          error: 'Credenciais inválidas'
        });
      }

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_ACCESS_TOKEN_SECRET || 'nh-personal-access-token-secret-2024',
        { expiresIn: '24h' }
      );

      // Remove password from response
      const { passwordHash, ...userWithoutPassword } = user;

      return res.json({
        success: true,
        data: {
          user: userWithoutPassword,
          token
        }
      });
    } catch (error) {
      console.error('Login error:', error);
      return res.status(500).json({
        success: false,
        error: 'Erro interno do servidor'
      });
    }
  },

  // Get current user
  getMe: async (req: Request, res: Response) => {
    try {
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
        data: userWithoutPassword
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
  }
}; 