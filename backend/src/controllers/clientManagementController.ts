import { Request, Response } from 'express';
import databaseService from '../services/databaseService';

interface CreateClientManagementRequest {
  clientId: number;
  weeklySessions: number;
  sessionDurationMinutes: number;
  notes?: string;
}

interface UpdateClientManagementRequest {
  status?: 'active' | 'inactive' | 'suspended' | 'completed';
  weeklySessions?: number;
  sessionDurationMinutes?: number;
  notes?: string;
  endDate?: string;
}

interface CreatePaymentRequest {
  clientSubscriptionId: number;
  paymentMethodId: number;
  amount: number;
  paymentDate: string;
  dueDate: string;
  paymentReference?: string;
  notes?: string;
  installments?: number;
}

export const clientManagementController = {
  // Listar todos os clientes do trainer
  getClients: async (req: Request, res: Response) => {
    try {
      const trainerId = req.user!.id;
      const { status, page = 1, limit = 10 } = req.query;

      const prisma = await databaseService.getPrismaClient();

      const where: any = { trainerId };
      if (status) {
        where.status = status;
      }

      const skip = (Number(page) - 1) * Number(limit);

      const [clients, total] = await Promise.all([
        prisma.clientManagement.findMany({
          where,
          include: {
            client: {
              select: {
                id: true,
                name: true,
                email: true,
                phone: true,
                profileImageUrl: true,
                clientProfile: true
              }
            },
            subscriptions: {
              include: {
                paymentPlan: true,
                payments: {
                  include: {
                    paymentMethod: true,
                    installments: true
                  }
                }
              }
            }
          },
          skip,
          take: Number(limit),
          orderBy: { createdAt: 'desc' }
        }),
        prisma.clientManagement.count({ where })
      ]);

      // Calcular estatísticas financeiras para cada cliente
      const clientsWithStats = clients.map((client: any) => {
        const totalPaid = client.subscriptions.reduce((sum: number, sub: any) => {
          return sum + sub.payments.reduce((paymentSum: number, payment: any) => {
            return paymentSum + (payment.status === 'paid' ? Number(payment.amount) : 0);
          }, 0);
        }, 0);

        const totalPending = client.subscriptions.reduce((sum: number, sub: any) => {
          return sum + sub.payments.reduce((paymentSum: number, payment: any) => {
            return paymentSum + (payment.status === 'pending' ? Number(payment.amount) : 0);
          }, 0);
        }, 0);

        const totalOverdue = client.subscriptions.reduce((sum: number, sub: any) => {
          return sum + sub.payments.reduce((paymentSum: number, payment: any) => {
            return paymentSum + (payment.status === 'overdue' ? Number(payment.amount) : 0);
          }, 0);
        }, 0);

        return {
          ...client,
          financialStats: {
            totalPaid,
            totalPending,
            totalOverdue
          }
        };
      });

      res.json({
        success: true,
        data: {
          clients: clientsWithStats,
          pagination: {
            page: Number(page),
            limit: Number(limit),
            total,
            pages: Math.ceil(total / Number(limit))
          }
        }
      });
    } catch (error) {
      console.error('Get clients error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Obter um cliente específico
  getClient: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const trainerId = req.user!.id;

      const prisma = await databaseService.getPrismaClient();

      const clientManagement = await prisma.clientManagement.findFirst({
        where: {
          id: Number(id),
          trainerId
        },
        include: {
          client: {
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
              birthDate: true,
              gender: true,
              height: true,
              weight: true,
              profileImageUrl: true,
              clientProfile: true
            }
          },
          subscriptions: {
            include: {
              paymentPlan: true,
              payments: {
                include: {
                  paymentMethod: true,
                  installments: true
                }
              }
            }
          }
        }
      });

      if (!clientManagement) {
        return res.status(404).json({
          success: false,
          error: 'Client not found'
        });
      }

      res.json({
        success: true,
        data: clientManagement
      });
    } catch (error) {
      console.error('Get client error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Adicionar novo cliente
  addClient: async (req: Request, res: Response) => {
    try {
      const trainerId = req.user!.id;
      const { clientId, weeklySessions, sessionDurationMinutes, notes }: CreateClientManagementRequest = req.body;

      const prisma = await databaseService.getPrismaClient();

      // Verificar se o cliente já existe para este trainer
      const existingClient = await prisma.clientManagement.findFirst({
        where: {
          trainerId,
          clientId
        }
      });

      if (existingClient) {
        return res.status(400).json({
          success: false,
          error: 'Client already exists for this trainer'
        });
      }

      // Verificar se o usuário é realmente um cliente
      const client = await prisma.user.findFirst({
        where: {
          id: clientId,
          role: 'client'
        }
      });

      if (!client) {
        return res.status(400).json({
          success: false,
          error: 'Invalid client ID'
        });
      }

      const clientManagement = await prisma.clientManagement.create({
        data: {
          trainerId,
          clientId,
          weeklySessions,
          sessionDurationMinutes,
          notes,
          startDate: new Date()
        },
        include: {
          client: {
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
              profileImageUrl: true
            }
          }
        }
      });

      res.status(201).json({
        success: true,
        data: clientManagement
      });
    } catch (error) {
      console.error('Add client error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Atualizar cliente
  updateClient: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const trainerId = req.user!.id;
      const updateData: UpdateClientManagementRequest = req.body;

      const prisma = await databaseService.getPrismaClient();

      const clientManagement = await prisma.clientManagement.findFirst({
        where: {
          id: Number(id),
          trainerId
        }
      });

      if (!clientManagement) {
        return res.status(404).json({
          success: false,
          error: 'Client not found'
        });
      }

      const updatedClient = await prisma.clientManagement.update({
        where: { id: Number(id) },
        data: {
          ...updateData,
          endDate: updateData.endDate ? new Date(updateData.endDate) : undefined
        },
        include: {
          client: {
            select: {
              id: true,
              name: true,
              email: true,
              phone: true,
              profileImageUrl: true
            }
          }
        }
      });

      res.json({
        success: true,
        data: updatedClient
      });
    } catch (error) {
      console.error('Update client error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Remover cliente
  removeClient: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const trainerId = req.user!.id;

      const prisma = await databaseService.getPrismaClient();

      const clientManagement = await prisma.clientManagement.findFirst({
        where: {
          id: Number(id),
          trainerId
        }
      });

      if (!clientManagement) {
        return res.status(404).json({
          success: false,
          error: 'Client not found'
        });
      }

      await prisma.clientManagement.delete({
        where: { id: Number(id) }
      });

      res.json({
        success: true,
        message: 'Client removed successfully'
      });
    } catch (error) {
      console.error('Remove client error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Obter estatísticas financeiras do trainer
  getFinancialStats: async (req: Request, res: Response) => {
    try {
      const trainerId = req.user!.id;
      const { startDate, endDate } = req.query;

      const prisma = await databaseService.getPrismaClient();

      const where: any = {
        trainer: { id: trainerId }
      };

      if (startDate && endDate) {
        where.paymentDate = {
          gte: new Date(startDate as string),
          lte: new Date(endDate as string)
        };
      }

      const payments = await prisma.payment.findMany({
        where: {
          clientSubscription: {
            clientManagement: {
              trainerId
            }
          },
          ...(startDate && endDate ? {
            paymentDate: {
              gte: new Date(startDate as string),
              lte: new Date(endDate as string)
            }
          } : {})
        },
        include: {
          paymentMethod: true,
          clientSubscription: {
            include: {
              clientManagement: {
                include: {
                  client: {
                    select: {
                      id: true,
                      name: true
                    }
                  }
                }
              }
            }
          }
        }
      });

      const stats = {
        totalReceived: 0,
        totalPending: 0,
        totalOverdue: 0,
        totalClients: 0,
        paymentsByMethod: {} as any,
        paymentsByClient: {} as any
      };

      const clientIds = new Set();

      payments.forEach((payment: any) => {
        const amount = Number(payment.amount);
        const clientId = payment.clientSubscription.clientManagement.client.id;
        const clientName = payment.clientSubscription.clientManagement.client.name;
        const methodName = payment.paymentMethod.name;

        clientIds.add(clientId);

        // Estatísticas por status
        if (payment.status === 'paid') {
          stats.totalReceived += amount;
        } else if (payment.status === 'pending') {
          stats.totalPending += amount;
        } else if (payment.status === 'overdue') {
          stats.totalOverdue += amount;
        }

        // Estatísticas por método de pagamento
        if (!stats.paymentsByMethod[methodName]) {
          stats.paymentsByMethod[methodName] = { total: 0, count: 0 };
        }
        stats.paymentsByMethod[methodName].total += amount;
        stats.paymentsByMethod[methodName].count += 1;

        // Estatísticas por cliente
        if (!stats.paymentsByClient[clientName]) {
          stats.paymentsByClient[clientName] = { total: 0, count: 0 };
        }
        stats.paymentsByClient[clientName].total += amount;
        stats.paymentsByClient[clientName].count += 1;
      });

      stats.totalClients = clientIds.size;

      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      console.error('Get financial stats error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  }
}; 