export const productionConfig = {
  // Configurações do Servidor
  server: {
    port: process.env.PORT || 3001,
    host: '0.0.0.0',
    cors: {
      origin: process.env.FRONTEND_URL || 'https://nhpersonal.com',
      credentials: true,
    },
  },

  // Configurações do Banco de Dados
  database: {
    host: process.env.DB_HOST || 'personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com',
    port: parseInt(process.env.DB_PORT || '3306'),
    username: process.env.DB_USERNAME || 'admin',
    password: process.env.DB_PASSWORD_ENCRYPTED || 'Rdms95gn!', // Senha descriptografada
    database: process.env.DB_NAME || 'personal_trainer_db',
    pool: {
      min: 2,
      max: 10,
    },
  },

  // Configurações de Segurança
  security: {
    jwt: {
      accessTokenSecret: process.env.JWT_ACCESS_TOKEN_SECRET || 'nh-personal-access-token-secret-2024',
      refreshTokenSecret: process.env.JWT_REFRESH_TOKEN_SECRET || 'nh-personal-refresh-token-secret-2024',
      accessTokenExpiresIn: '15m',
      refreshTokenExpiresIn: '7d',
    },
    bcrypt: {
      saltRounds: 12,
    },
    encryption: {
      key: process.env.ENCRYPTION_KEY || 'nh-personal-encryption-key-2024',
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
}; 