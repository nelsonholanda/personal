import { Request, Response } from 'express';
import databaseService from '../services/databaseService';
import { PaymentStatus, AppointmentStatus } from '@prisma/client';

export const dashboardController = {
  // Obter estatísticas do dashboard
  getStats: async (req: Request, res: Response) => {
    try {
      const prisma = await databaseService.getPrismaClient();
      const trainerId = req.user!.id;

      // Contar clientes ativos
      const activeClients = await prisma.user.count({
        where: {
          role: 'client',
          isActive: true
        }
      });

      // Calcular receita do mês atual
      const currentMonth = new Date();
      const startOfMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), 1);
      const endOfMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 0);

      const monthlyPayments = await prisma.payment.aggregate({
        where: {
          createdAt: {
            gte: startOfMonth,
            lte: endOfMonth
          },
          status: PaymentStatus.paid
        },
        _sum: {
          amount: true
        }
      });

      const monthlyRevenue = monthlyPayments._sum?.amount || 0;

      // Contar sessões de hoje
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const todaySessions = await prisma.appointment.count({
        where: {
          appointmentDate: {
            gte: today,
            lt: tomorrow
          }
        }
      });

      // Contar pagamentos pendentes
      const pendingPayments = await prisma.payment.count({
        where: {
          status: PaymentStatus.pending
        }
      });

      res.json({
        success: true,
        activeClients,
        monthlyRevenue,
        todaySessions,
        pendingPayments
      });
    } catch (error) {
      console.error('Get stats error:', error);
      res.status(500).json({
        success: false,
        error: 'Erro interno do servidor'
      });
    }
  },

  // Obter atividade recente
  getRecentActivity: async (req: Request, res: Response) => {
    try {
      const prisma = await databaseService.getPrismaClient();

      // Buscar atividades recentes (últimos 10 registros)
      const recentActivity = await prisma.$queryRaw`
        SELECT 
          'payment' as type,
          CONCAT('Pagamento de R$ ', FORMAT(amount, 2, 'pt_BR'), ' recebido') as description,
          createdAt as timestamp
        FROM Payment 
        WHERE status = 'completed'
        UNION ALL
        SELECT 
          'client' as type,
          CONCAT('Novo cliente cadastrado: ', name) as description,
          createdAt as timestamp
        FROM User 
        WHERE role = 'client'
        ORDER BY timestamp DESC
        LIMIT 10
      `;

      res.json({
        success: true,
        data: recentActivity
      });
    } catch (error) {
      console.error('Get recent activity error:', error);
      res.status(500).json({
        success: false,
        error: 'Erro interno do servidor'
      });
    }
  },

  // Obter próximas sessões
  getUpcomingSessions: async (req: Request, res: Response) => {
    try {
      const prisma = await databaseService.getPrismaClient();

      // Buscar próximas sessões (próximos 7 dias)
      const upcomingSessions = await prisma.appointment.findMany({
        where: {
          appointmentDate: {
            gte: new Date()
          }
        },
        include: {
          client: {
            select: {
              name: true
            }
          }
        },
        orderBy: {
          appointmentDate: 'asc'
        },
        take: 10
      });

      const formattedSessions = upcomingSessions.map((session: any) => ({
        id: session.id,
        clientName: session.client.name,
        date: session.appointmentDate.toISOString().split('T')[0],
        time: session.appointmentTime,
        status: session.status
      }));

      res.json({
        success: true,
        data: formattedSessions
      });
    } catch (error) {
      console.error('Get upcoming sessions error:', error);
      res.status(500).json({
        success: false,
        error: 'Erro interno do servidor'
      });
    }
  }
}; 