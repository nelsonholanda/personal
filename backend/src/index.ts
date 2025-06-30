import 'express-async-errors';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import path from 'path';

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

// Serve static files from the React app build
const frontendBuildPath = path.join(__dirname, '../frontend/build');
console.log('🔍 Verificando frontend build em:', frontendBuildPath);

if (process.env.NODE_ENV === 'production') {
  // Verificar se o diretório de build existe
  if (require('fs').existsSync(frontendBuildPath)) {
    console.log('✅ Frontend build encontrado, servindo arquivos estáticos');
    
    // Serve static files from the React app build
    app.use(express.static(frontendBuildPath));
    
    // Handle React routing, return all requests to React app
    app.get('*', (req, res) => {
      const indexPath = path.join(frontendBuildPath, 'index.html');
      if (require('fs').existsSync(indexPath)) {
        res.sendFile(indexPath);
      } else {
        console.error('❌ index.html não encontrado em:', indexPath);
        res.status(404).json({ error: 'Frontend não encontrado' });
      }
    });
  } else {
    console.warn('⚠️ Frontend build não encontrado em:', frontendBuildPath);
    console.log('📋 Tentando caminhos alternativos...');
    
    // Tentar caminhos alternativos
    const alternativePaths = [
      path.join(__dirname, '../../frontend/build'),
      path.join(__dirname, '../../../frontend/build'),
      path.join(process.cwd(), 'frontend/build')
    ];
    
    let frontendFound = false;
    for (const altPath of alternativePaths) {
      if (require('fs').existsSync(altPath)) {
        console.log('✅ Frontend encontrado em:', altPath);
        app.use(express.static(altPath));
        app.get('*', (req, res) => {
          res.sendFile(path.join(altPath, 'index.html'));
        });
        frontendFound = true;
        break;
      }
    }
    
    if (!frontendFound) {
      console.error('❌ Frontend build não encontrado em nenhum caminho');
      app.get('*', (req, res) => {
        res.status(404).json({ 
          error: 'Frontend não encontrado',
          message: 'O build do frontend não foi encontrado. Execute: cd frontend && npm run build'
        });
      });
    }
  }
} else {
  console.log('🔧 Modo desenvolvimento - frontend não será servido pelo backend');
}

// Error handling middleware (apenas para rotas da API)
app.use('/api/*', notFound);
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