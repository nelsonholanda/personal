import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

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

interface UpdatePaymentRequest {
  status?: 'pending' | 'paid' | 'overdue' | 'cancelled';
  paymentDate?: string;
  paymentReference?: string;
  notes?: string;
}

export const paymentController = {
  // Listar pagamentos do trainer
  getPayments: async (req: Request, res: Response) => {
    try {
      const trainerId = req.user!.id;
      const { status, clientId, startDate, endDate, page = 1, limit = 10 } = req.query;

      const where: any = {
        clientSubscription: {
          clientManagement: {
            trainerId
          }
        }
      };

      if (status) {
        where.status = status;
      }

      if (clientId) {
        where.clientSubscription = {
          ...where.clientSubscription,
          clientManagement: {
            ...where.clientSubscription.clientManagement,
            clientId: Number(clientId)
          }
        };
      }

      if (startDate && endDate) {
        where.paymentDate = {
          gte: new Date(startDate as string),
          lte: new Date(endDate as string)
        };
      }

      const skip = (Number(page) - 1) * Number(limit);

      const [payments, total] = await Promise.all([
        prisma.payment.findMany({
          where,
          include: {
            paymentMethod: true,
            installments: true,
            clientSubscription: {
              include: {
                paymentPlan: true,
                clientManagement: {
                  include: {
                    client: {
                      select: {
                        id: true,
                        name: true,
                        email: true
                      }
                    }
                  }
                }
              }
            }
          },
          skip,
          take: Number(limit),
          orderBy: { paymentDate: 'desc' }
        }),
        prisma.payment.count({ where })
      ]);

      res.json({
        success: true,
        data: {
          payments,
          pagination: {
            page: Number(page),
            limit: Number(limit),
            total,
            pages: Math.ceil(total / Number(limit))
          }
        }
      });
    } catch (error) {
      console.error('Get payments error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Obter um pagamento específico
  getPayment: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const trainerId = req.user!.id;

      const payment = await prisma.payment.findFirst({
        where: {
          id: Number(id),
          clientSubscription: {
            clientManagement: {
              trainerId
            }
          }
        },
        include: {
          paymentMethod: true,
          installments: true,
          clientSubscription: {
            include: {
              paymentPlan: true,
              clientManagement: {
                include: {
                  client: {
                    select: {
                      id: true,
                      name: true,
                      email: true
                    }
                  }
                }
              }
            }
          }
        }
      });

      if (!payment) {
        return res.status(404).json({
          success: false,
          error: 'Payment not found'
        });
      }

      res.json({
        success: true,
        data: payment
      });
    } catch (error) {
      console.error('Get payment error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Criar novo pagamento
  createPayment: async (req: Request, res: Response) => {
    try {
      const trainerId = req.user!.id;
      const {
        clientSubscriptionId,
        paymentMethodId,
        amount,
        paymentDate,
        dueDate,
        paymentReference,
        notes,
        installments = 1
      }: CreatePaymentRequest = req.body;

      // Verificar se a assinatura pertence ao trainer
      const subscription = await prisma.clientSubscription.findFirst({
        where: {
          id: clientSubscriptionId,
          clientManagement: {
            trainerId
          }
        }
      });

      if (!subscription) {
        return res.status(404).json({
          success: false,
          error: 'Subscription not found'
        });
      }

      // Criar o pagamento
      const payment = await prisma.payment.create({
        data: {
          clientSubscriptionId,
          paymentMethodId,
          amount,
          paymentDate: new Date(paymentDate),
          dueDate: new Date(dueDate),
          paymentReference,
          notes
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

      // Criar parcelas se necessário
      if (installments > 1) {
        const installmentAmount = amount / installments;
        const installmentDates = [];

        for (let i = 0; i < installments; i++) {
          const installmentDate = new Date(dueDate);
          installmentDate.setMonth(installmentDate.getMonth() + i);
          installmentDates.push(installmentDate);
        }

        await Promise.all(
          installmentDates.map((date, index) =>
            prisma.paymentInstallment.create({
              data: {
                paymentId: payment.id,
                installmentNumber: index + 1,
                amount: installmentAmount,
                dueDate: date
              }
            })
          )
        );
      }

      res.status(201).json({
        success: true,
        data: payment
      });
    } catch (error) {
      console.error('Create payment error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Atualizar pagamento
  updatePayment: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const trainerId = req.user!.id;
      const updateData: UpdatePaymentRequest = req.body;

      const payment = await prisma.payment.findFirst({
        where: {
          id: Number(id),
          clientSubscription: {
            clientManagement: {
              trainerId
            }
          }
        }
      });

      if (!payment) {
        return res.status(404).json({
          success: false,
          error: 'Payment not found'
        });
      }

      const updatedPayment = await prisma.payment.update({
        where: { id: Number(id) },
        data: {
          ...updateData,
          paymentDate: updateData.paymentDate ? new Date(updateData.paymentDate) : undefined
        },
        include: {
          paymentMethod: true,
          installments: true,
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

      res.json({
        success: true,
        data: updatedPayment
      });
    } catch (error) {
      console.error('Update payment error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Marcar pagamento como pago
  markAsPaid: async (req: Request, res: Response) => {
    try {
      const { id } = req.params;
      const trainerId = req.user!.id;
      const { paymentDate, paymentReference } = req.body;

      const payment = await prisma.payment.findFirst({
        where: {
          id: Number(id),
          clientSubscription: {
            clientManagement: {
              trainerId
            }
          }
        }
      });

      if (!payment) {
        return res.status(404).json({
          success: false,
          error: 'Payment not found'
        });
      }

      const updatedPayment = await prisma.payment.update({
        where: { id: Number(id) },
        data: {
          status: 'paid',
          paymentDate: paymentDate ? new Date(paymentDate) : new Date(),
          paymentReference
        },
        include: {
          paymentMethod: true,
          installments: true
        }
      });

      // Atualizar parcelas se existirem
      if (updatedPayment.installments.length > 0) {
        await Promise.all(
          updatedPayment.installments.map((installment: any) =>
            prisma.paymentInstallment.update({
              where: { id: installment.id },
              data: {
                status: 'paid',
                paymentDate: paymentDate ? new Date(paymentDate) : new Date()
              }
            })
          )
        );
      }

      res.json({
        success: true,
        data: updatedPayment
      });
    } catch (error) {
      console.error('Mark payment as paid error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Obter métodos de pagamento
  getPaymentMethods: async (req: Request, res: Response) => {
    try {
      const paymentMethods = await prisma.paymentMethod.findMany({
        where: { isActive: true },
        orderBy: { name: 'asc' }
      });

      res.json({
        success: true,
        data: paymentMethods
      });
    } catch (error) {
      console.error('Get payment methods error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  },

  // Obter planos de pagamento
  getPaymentPlans: async (req: Request, res: Response) => {
    try {
      const paymentPlans = await prisma.paymentPlan.findMany({
        where: { isActive: true },
        orderBy: { price: 'asc' }
      });

      res.json({
        success: true,
        data: paymentPlans
      });
    } catch (error) {
      console.error('Get payment plans error:', error);
      res.status(500).json({
        success: false,
        error: 'Server error'
      });
    }
  }
}; 