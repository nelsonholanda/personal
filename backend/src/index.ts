import 'express-async-errors';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

// Import routes
import authRoutes from './routes/auth';
import clientManagementRoutes from './routes/clientManagement';
import paymentRoutes from './routes/payments';
import passwordRoutes from './routes/passwords';
import dashboardRoutes from './routes/dashboard';
import adminRoutes from './routes/admin';

// Import middleware
import { errorHandler } from './middleware/errorHandler';
import { notFound } from './middleware/notFound';
import { authMiddleware } from './middleware/auth';

// Import Database Service
import databaseService from './services/databaseService';

// Load environment variables
dotenv.config();

const app = express();
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
app.use('/api/client-management', authMiddleware, clientManagementRoutes);
app.use('/api/payments', authMiddleware, paymentRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/admin', adminRoutes);

// Error handling middleware
app.use(notFound);
app.use(errorHandler);

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('🛑 SIGTERM recebido, encerrando servidor...');
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('🛑 SIGINT recebido, encerrando servidor...');
  process.exit(0);
});

// Start server
const startServer = async () => {
  try {
    // Inicializar serviço de banco de dados
    await databaseService.initialize();
    
    // Obter configurações do banco
    const dbConfig = await databaseService.getDatabaseConfig();
    console.log('🔐 Configuração do banco de dados carregada');
    console.log(`📍 Host: ${dbConfig.host}`);
    console.log(`👤 Usuário: ${dbConfig.username}`);
    console.log(`🗄️ Database: ${dbConfig.database}`);

    // Testar conexão com o banco
    const connectionTest = await databaseService.testConnection();
    if (!connectionTest) {
      throw new Error('Falha na conexão com o banco de dados');
    }

    // Executar migrações se necessário
    if (process.env.NODE_ENV === 'production') {
      console.log('🔄 Executando migrações do banco de dados...');
      await databaseService.runMigrations();
    }

    app.listen(PORT, () => {
      console.log(`🚀 NH-Personal Server running on port ${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🔗 Health check: http://localhost:${PORT}/health`);
      console.log(`📚 API Documentation: http://localhost:${PORT}/api`);
      
      if (process.env.NODE_ENV === 'development') {
        console.log(`👤 Admin user: nholanda`);
        console.log(`🔑 Admin password: [PROTECTED]`);
      }
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

export default app; 