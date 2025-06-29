import { Request, Response } from 'express';
import databaseService from '../services/databaseService';
import bcrypt from 'bcryptjs';

export const adminController = {
  // Listar todos os personais
  listTrainers: async (req: Request, res: Response) => {
    try {
      const prisma = await databaseService.getPrismaClient();
      const trainers = await prisma.user.findMany({
        where: { role: 'trainer' },
        include: { trainerProfile: true }
      });
      res.json({ success: true, data: trainers });
    } catch (error) {
      res.status(500).json({ success: false, error: 'Erro ao listar personais' });
    }
  },

  // Criar personal
  createTrainer: async (req: Request, res: Response) => {
    try {
      const { name, email, password, phone, birthDate, gender, height, weight, specialization, experienceYears, certifications, bio, hourlyRate, availability } = req.body;
      const prisma = await databaseService.getPrismaClient();
      const existing = await prisma.user.findUnique({ where: { email } });
      if (existing) return res.status(400).json({ success: false, error: 'Email já cadastrado' });
      const passwordHash = await bcrypt.hash(password, 12);
      const user = await prisma.user.create({
        data: {
          name, email, passwordHash, role: 'trainer', phone, birthDate, gender, height, weight, isActive: true,
          trainerProfile: {
            create: { specialization, experienceYears, certifications, bio, hourlyRate, availability }
          }
        },
        include: { trainerProfile: true }
      });
      res.status(201).json({ success: true, data: user });
    } catch (error) {
      res.status(500).json({ success: false, error: 'Erro ao criar personal' });
    }
  },

  // Editar personal
  updateTrainer: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const { name, phone, birthDate, gender, height, weight, specialization, experienceYears, certifications, bio, hourlyRate, availability, isActive } = req.body;
      const prisma = await databaseService.getPrismaClient();
      const user = await prisma.user.update({
        where: { id: parseInt(id) },
        data: {
          name, phone, birthDate, gender, height, weight, isActive,
          trainerProfile: {
            update: { specialization, experienceYears, certifications, bio, hourlyRate, availability }
          }
        },
        include: { trainerProfile: true }
      });
      res.json({ success: true, data: user });
    } catch (error) {
      res.status(500).json({ success: false, error: 'Erro ao editar personal' });
    }
  },

  // Ativar/desativar personal
  activateTrainer: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const { isActive } = req.body;
      const prisma = await databaseService.getPrismaClient();
      const user = await prisma.user.update({ where: { id: parseInt(id) }, data: { isActive } });
      res.json({ success: true, data: user });
    } catch (error) {
      res.status(500).json({ success: false, error: 'Erro ao ativar/desativar personal' });
    }
  },

  // Resetar senha de personal
  resetTrainerPassword: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const { newPassword } = req.body;
      const prisma = await databaseService.getPrismaClient();
      const passwordHash = await bcrypt.hash(newPassword, 12);
      await prisma.user.update({ where: { id: parseInt(id) }, data: { passwordHash } });
      res.json({ success: true, message: 'Senha redefinida com sucesso' });
    } catch (error) {
      res.status(500).json({ success: false, error: 'Erro ao resetar senha' });
    }
  },

  // Remover personal
  deleteTrainer: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const prisma = await databaseService.getPrismaClient();
      await prisma.user.delete({ where: { id: parseInt(id) } });
      res.json({ success: true, message: 'Personal removido com sucesso' });
    } catch (error) {
      res.status(500).json({ success: false, error: 'Erro ao remover personal' });
    }
  },

  // Listar todos os usuários
  listUsers: async (req: Request, res: Response) => {
    try {
      const prisma = await databaseService.getPrismaClient();
      const users = await prisma.user.findMany({ include: { trainerProfile: true, clientProfile: true } });
      res.json({ success: true, data: users });
    } catch (error) {
      res.status(500).json({ success: false, error: 'Erro ao listar usuários' });
    }
  },

  // Atualizar papel do usuário
  updateUserRole: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const { role } = req.body;
      const prisma = await databaseService.getPrismaClient();
      const user = await prisma.user.update({ where: { id: parseInt(id) }, data: { role } });
      res.json({ success: true, data: user });
    } catch (error) {
      res.status(500).json({ success: false, error: 'Erro ao atualizar papel do usuário' });
    }
  },

  // Estatísticas globais
  getStats: async (req: Request, res: Response) => {
    try {
      const prisma = await databaseService.getPrismaClient();
      const totalUsers = await prisma.user.count();
      const totalTrainers = await prisma.user.count({ where: { role: 'trainer' } });
      const totalClients = await prisma.user.count({ where: { role: 'client' } });
      const totalActive = await prisma.user.count({ where: { isActive: true } });
      res.json({ success: true, data: { totalUsers, totalTrainers, totalClients, totalActive } });
    } catch (error) {
      res.status(500).json({ success: false, error: 'Erro ao buscar estatísticas' });
    }
  }
}; 