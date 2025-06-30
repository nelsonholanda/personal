import encryptionService from '../services/encryptionService';

// Configurações de produção
export const productionConfig = {
  // Configurações do banco de dados
  database: {
    host: process.env.RDS_HOST || 'personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com',
    port: parseInt(process.env.RDS_PORT || '3306'),
    username: process.env.RDS_USERNAME || 'admin',
    // Senha criptografada - descriptografar automaticamente
    password: process.env.RDS_PASSWORD_ENCRYPTED || encryptionService.encryptDatabasePassword('Rdms95gn!'),
    database: process.env.RDS_DATABASE || 'personal_trainer_db',
    ssl: true,
    connectionLimit: 10,
    acquireTimeout: 60000,
    timeout: 60000,
    reconnect: true
  },

  // Configurações de segurança
  security: {
    jwtSecret: process.env.JWT_ACCESS_TOKEN_SECRET || 'nh-personal-access-token-secret-2024',
    jwtRefreshSecret: process.env.JWT_REFRESH_TOKEN_SECRET || 'nh-personal-refresh-token-secret-2024',
    encryptionKey: process.env.ENCRYPTION_KEY || 'nh-personal-encryption-key-2024',
    bcrypt: {
      saltRounds: 12
    },
    sessionTimeout: 24 * 60 * 60 * 1000, // 24 horas
    passwordPolicy: {
      minLength: 8,
      requireUppercase: true,
      requireLowercase: true,
      requireNumbers: true,
      requireSpecialChars: true,
      maxHistory: 5
    }
  },

  // Configurações de email
  email: {
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.EMAIL_PORT || '587'),
    secure: false,
    auth: {
      user: process.env.EMAIL_USER || '',
      pass: process.env.EMAIL_PASSWORD_ENCRYPTED || encryptionService.encryptSensitivePassword('')
    },
    from: process.env.EMAIL_FROM || 'noreply@nhpersonal.com'
  },

  // Configurações de logging
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    file: process.env.LOG_FILE || '/var/log/nh-personal/app.log',
    maxSize: '10m',
    maxFiles: 5
  },

  // Configurações de rate limiting
  rateLimit: {
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 100, // limite por IP
    message: 'Muitas requisições deste IP, tente novamente em 15 minutos'
  },

  // Configurações de CORS
  cors: {
    origin: process.env.FRONTEND_URL || 'http://localhost:3000',
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
  },

  // Configurações de backup
  backup: {
    enabled: true,
    schedule: '0 2 * * *', // 2 AM diariamente
    retention: 30, // dias
    path: '/var/backups/nh-personal'
  },

  // Configurações de monitoramento
  monitoring: {
    enabled: true,
    healthCheckInterval: 30000, // 30 segundos
    metricsEndpoint: '/metrics'
  }
};

// Função para obter configuração descriptografada
export const getDecryptedConfig = () => {
  const config = { ...productionConfig };
  
  // Descriptografar senhas se necessário
  if (encryptionService.isEncrypted(config.database.password)) {
    config.database.password = encryptionService.decryptDatabasePassword(config.database.password);
  }
  
  if (encryptionService.isEncrypted(config.email.auth.pass)) {
    config.email.auth.pass = encryptionService.decryptSensitivePassword(config.email.auth.pass);
  }
  
  return config;
};

export default productionConfig; 