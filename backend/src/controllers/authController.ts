import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

interface RegisterRequest {
  name: string;
  email: string;
  password: string;
  role: 'trainer' | 'client';
  phone?: string;
  birthDate?: string;
  gender?: 'male' | 'female' | 'other';
}

interface LoginRequest {
  email: string;
  password: string;
}

export const authController = {
  // Register new user
  register: async (req: Request, res: Response) => {
    try {
      const { name, email, password, role, phone, birthDate, gender }: RegisterRequest = req.body;

      // Check if user already exists
      const existingUser = await prisma.user.findUnique({
        where: { email }
      });

      if (existingUser) {
        return res.status(400).json({
          success: false,
          error: 'User already exists with this email'
        });
      }

      // Hash password
      const salt = await bcrypt.genSalt(10);
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
          gender
        },
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
          phone: true,
          birthDate: true,
          gender: true,
          createdAt: true
        }
      });

      // Create profile based on role
      if (role === 'trainer') {
        await prisma.trainerProfile.create({
          data: {
            userId: user.id
          }
        });
      } else if (role === 'client') {
        await prisma.clientProfile.create({
          data: {
            userId: user.id
          }
        });
      }

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET!,
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
      res.status(500).json({
        success: false,
        error: 'Server error'
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
          error: 'Invalid credentials'
        });
      }

      // Check if user is active
      if (!user.isActive) {
        return res.status(400).json({
          success: false,
          error: 'Account is deactivated'
        });
      }

      // Verify password
      const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
      if (!isPasswordValid) {
        return res.status(400).json({
          success: false,
          error: 'Invalid credentials'
        });
      }

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET!,
        { expiresIn: '24h' }
      );

      // Remove password from response
      const { passwordHash, ...userWithoutPassword } = user;

      res.json({
        success: true,
        data: {
          user: userWithoutPassword,
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
          error: 'User not found'
        });
      }

      // Remove password from response
      const { passwordHash, ...userWithoutPassword } = user;

      res.json({
        success: true,
        data: userWithoutPassword
      });
    } catch (error) {
      console.error('Get me error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Logout (client-side token removal)
  logout: async (req: Request, res: Response) => {
    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  },

  // Refresh token
  refreshToken: async (req: Request, res: Response) => {
    try {
      const token = req.header('Authorization')?.replace('Bearer ', '');

      if (!token) {
        return res.status(401).json({
          success: false,
          error: 'No token provided'
        });
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;
      
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
          error: 'Invalid token'
        });
      }

      // Generate new token
      const newToken = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET!,
        { expiresIn: '24h' }
      );

      res.json({
        success: true,
        data: {
          token: newToken
        }
      });
    } catch (error) {
      console.error('Refresh token error:', error);
      res.status(401).json({
        success: false,
        error: 'Invalid token'
      });
    }
  }
}; 