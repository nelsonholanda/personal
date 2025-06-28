import 'express-async-errors';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

// Import routes
import authRoutes from './routes/auth';
import userRoutes from './routes/users';
import trainerRoutes from './routes/trainers';
import clientRoutes from './routes/clients';
import clientManagementRoutes from './routes/clientManagement';
import paymentRoutes from './routes/payments';
import trainingPlanRoutes from './routes/trainingPlans';
import workoutRoutes from './routes/workouts';
import exerciseRoutes from './routes/exercises';
import appointmentRoutes from './routes/appointments';
import progressRoutes from './routes/progress';
import messageRoutes from './routes/messages';
import notificationRoutes from './routes/notifications';
import passwordRoutes from './routes/passwords';

// Import middleware
import { errorHandler } from './middleware/errorHandler';
import { notFound } from './middleware/notFound';
import { authMiddleware } from './middleware/auth';

// Import AWS Secrets Manager
import awsSecretsManager from './services/awsSecretsManager';

// Load environment variables
dotenv.config();

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3001;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    success: false,
    error: 'Muitas requisições deste IP, tente novamente em 15 minutos'
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Compression middleware
app.use(compression());

// Logging middleware
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'NH-Personal API está funcionando',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/passwords', passwordRoutes);
app.use('/api/users', authMiddleware, userRoutes);
app.use('/api/trainers', authMiddleware, trainerRoutes);
app.use('/api/clients', authMiddleware, clientRoutes);
app.use('/api/client-management', authMiddleware, clientManagementRoutes);
app.use('/api/payments', authMiddleware, paymentRoutes);
app.use('/api/training-plans', authMiddleware, trainingPlanRoutes);
app.use('/api/workouts', authMiddleware, workoutRoutes);
app.use('/api/exercises', authMiddleware, exerciseRoutes);
app.use('/api/appointments', authMiddleware, appointmentRoutes);
app.use('/api/progress', authMiddleware, progressRoutes);
app.use('/api/messages', authMiddleware, messageRoutes);
app.use('/api/notifications', authMiddleware, notificationRoutes);

// Error handling middleware
app.use(notFound);
app.use(errorHandler);

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('🛑 SIGTERM recebido, encerrando servidor...');
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('🛑 SIGINT recebido, encerrando servidor...');
  await prisma.$disconnect();
  process.exit(0);
});

// Start server
const startServer = async () => {
  try {
    // Test database connection
    await prisma.$connect();
    console.log('✅ Database connected successfully');

    // Configura a URL do banco de dados usando AWS Secrets Manager se disponível
    if (awsSecretsManager.isConfigured()) {
      console.log('🔐 Usando AWS Secrets Manager para configurações');
      
      try {
        const databaseURL = await awsSecretsManager.getDatabaseURL();
        process.env.DATABASE_URL = databaseURL;
        console.log('✅ Configuração do banco de dados carregada do AWS Secrets Manager');
      } catch (error) {
        console.warn('⚠️ Erro ao carregar configurações do AWS Secrets Manager, usando configurações locais');
        process.env.DATABASE_URL = awsSecretsManager.getLocalDatabaseURL();
      }
    } else {
      console.log('🔧 Usando configurações locais');
      process.env.DATABASE_URL = awsSecretsManager.getLocalDatabaseURL();
    }

    app.listen(PORT, () => {
      console.log(`🚀 NH-Personal Server running on port ${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🔗 Health check: http://localhost:${PORT}/health`);
      console.log(`📚 API Documentation: http://localhost:${PORT}/api`);
      
      if (process.env.NODE_ENV === 'development') {
        console.log(`👤 Admin user: nholanda`);
        console.log(`🔑 Admin password: rdms95gn`);
      }
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

export default app; 