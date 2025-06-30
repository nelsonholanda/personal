const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');

// Importar rotas do backend
const authRoutes = require('./src/routes/auth');
const usersRoutes = require('./src/routes/users');
const clientsRoutes = require('./src/routes/clients');
const paymentsRoutes = require('./src/routes/payments');
const dashboardRoutes = require('./src/routes/dashboard');
const adminRoutes = require('./src/routes/admin');
const clientManagementRoutes = require('./src/routes/clientManagement');
const trainingPlansRoutes = require('./src/routes/trainingPlans');
const workoutsRoutes = require('./src/routes/workouts');
const exercisesRoutes = require('./src/routes/exercises');
const appointmentsRoutes = require('./src/routes/appointments');
const messagesRoutes = require('./src/routes/messages');
const notificationsRoutes = require('./src/routes/notifications');
const passwordsRoutes = require('./src/routes/passwords');

// Importar middlewares
const errorHandler = require('./src/middleware/errorHandler');
const notFound = require('./src/middleware/notFound');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares de segurança e performance
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
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'NH Gestão de Alunos - Container Único'
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/clients', clientsRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/client-management', clientManagementRoutes);
app.use('/api/training-plans', trainingPlansRoutes);
app.use('/api/workouts', workoutsRoutes);
app.use('/api/exercises', exercisesRoutes);
app.use('/api/appointments', appointmentsRoutes);
app.use('/api/messages', messagesRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/passwords', passwordsRoutes);

// Servir arquivos estáticos do React (build)
app.use(express.static(path.join(__dirname, 'frontend/build')));

// Fallback para React Router - todas as rotas não-API vão para o React
app.get('*', (req, res) => {
  // Se a rota não começa com /api, serve o React app
  if (!req.path.startsWith('/api')) {
    res.sendFile(path.join(__dirname, 'frontend/build/index.html'));
  } else {
    // Se começa com /api mas não foi encontrada, retorna 404
    res.status(404).json({ error: 'API endpoint not found' });
  }
});

// Middlewares de erro
app.use(notFound);
app.use(errorHandler);

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`🚀 NH Gestão de Alunos rodando na porta ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🌐 Frontend: http://localhost:${PORT}`);
  console.log(`🔧 API: http://localhost:${PORT}/api`);
});

module.exports = app; 