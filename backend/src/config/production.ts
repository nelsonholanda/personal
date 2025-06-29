export const productionConfig = {
  // Configurações do Servidor
  server: {
    port: parseInt(process.env.PORT || '3001'),
    host: process.env.HOST || '0.0.0.0',
  },

  // Configurações do Banco de Dados
  database: {
    host: process.env.DB_HOST || 'personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com',
    port: parseInt(process.env.DB_PORT || '3306'),
    username: process.env.DB_USERNAME || 'admin',
    password: process.env.DB_PASSWORD_ENCRYPTED || 'Rdms95gn!', // Senha descriptografada
    database: process.env.DB_NAME || 'personal_trainer_db',
  },

  // Configurações de Segurança
  security: {
    jwt: {
      secret: process.env.JWT_SECRET || '[JWT_SECRET]',
      expiresIn: process.env.JWT_EXPIRES_IN || '24h',
    },
    bcrypt: {
      saltRounds: 12,
    },
    encryption: {
      key: process.env.ENCRYPTION_KEY || '[ENCRYPTION_KEY]',
    },
    rateLimit: {
      windowMs: 15 * 60 * 1000, // 15 minutos
      max: 100, // limite por IP
    },
  },

  // Configurações de Log
  logging: {
    level: 'info',
    file: '/var/log/nh-personal/app.log',
  },

  // Configurações de Email
  email: {
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: false,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
    from: process.env.SMTP_FROM || 'noreply@nhpersonal.com',
  },

  // Configurações de Monitoramento
  monitoring: {
    enableHealthCheck: true,
    healthCheckInterval: 30000,
    enableMetrics: true,
    metricsPort: 9090,
  },

  // Configurações de CORS
  cors: {
    origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
    credentials: true,
  },
}; 