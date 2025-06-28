import awsSecretsManager from './awsSecretsManager';

interface DatabaseConfig {
  host: string;
  port: number;
  username: string;
  password: string;
  database: string;
}

class DatabaseService {
  private config: DatabaseConfig | null = null;
  private secretsLoaded = false;

  constructor() {
    // Configuração inicial será carregada quando necessário
  }

  /**
   * Carrega as configurações do banco de dados
   */
  private async loadConfig(): Promise<void> {
    if (this.secretsLoaded) return;

    try {
      // Tentar carregar do AWS Secrets Manager primeiro
      if (process.env.AWS_SECRET_NAME) {
        console.log('🔐 Carregando configurações do AWS Secrets Manager...');
        const secrets = await awsSecretsManager.getSecret(process.env.AWS_SECRET_NAME);
        
        this.config = {
          host: secrets.host || process.env.RDS_HOST || process.env.DB_HOST || '',
          port: parseInt(secrets.port || process.env.RDS_PORT || process.env.DB_PORT || '3306'),
          username: secrets.username || process.env.RDS_USERNAME || process.env.DB_USERNAME || '',
          password: secrets.password || process.env.RDS_PASSWORD || process.env.DB_PASSWORD || '',
          database: secrets.database || secrets.dbname || process.env.RDS_DATABASE || process.env.DB_NAME || '',
        };
      } else {
        // Fallback para variáveis de ambiente
        console.log('🔐 Carregando configurações das variáveis de ambiente...');
        this.config = {
          host: process.env.RDS_HOST || process.env.DB_HOST || '',
          port: parseInt(process.env.RDS_PORT || process.env.DB_PORT || '3306'),
          username: process.env.RDS_USERNAME || process.env.DB_USERNAME || '',
          password: process.env.RDS_PASSWORD || process.env.DB_PASSWORD || '',
          database: process.env.RDS_DATABASE || process.env.DB_NAME || '',
        };
      }

      // Validação das configurações
      if (!this.config.host || !this.config.username || !this.config.password || !this.config.database) {
        throw new Error('Configurações de banco de dados incompletas');
      }

      this.secretsLoaded = true;
      console.log('✅ Configurações de banco de dados carregadas com sucesso');
      console.log(`📍 Host: ${this.config.host}`);
      console.log(`👤 Usuário: ${this.config.username}`);
      console.log(`🗄️ Database: ${this.config.database}`);

    } catch (error) {
      console.error('❌ Erro ao carregar configurações do banco:', error);
      throw new Error('Falha ao carregar configurações do banco de dados');
    }
  }

  /**
   * Obtém a URL de conexão do banco de dados
   */
  async getDatabaseURL(): Promise<string> {
    await this.loadConfig();
    
    if (!this.config) {
      throw new Error('Configurações de banco não carregadas');
    }

    const { host, port, username, password, database } = this.config;
    
    // Codificar a senha para URL
    const encodedPassword = encodeURIComponent(password);
    
    return `mysql://${username}:${encodedPassword}@${host}:${port}/${database}`;
  }

  /**
   * Obtém a configuração do banco de dados
   */
  async getDatabaseConfig(): Promise<DatabaseConfig> {
    await this.loadConfig();
    
    if (!this.config) {
      throw new Error('Configurações de banco não carregadas');
    }

    return { ...this.config };
  }

  /**
   * Verifica se a conexão está configurada
   */
  async isConfigured(): Promise<boolean> {
    try {
      await this.loadConfig();
      return !!(this.config?.host && this.config?.username && this.config?.password);
    } catch (error) {
      return false;
    }
  }

  /**
   * Testa a conexão com o banco de dados
   */
  async testConnection(): Promise<boolean> {
    try {
      const { PrismaClient } = require('@prisma/client');
      const databaseURL = await this.getDatabaseURL();
      
      const prisma = new PrismaClient({
        datasources: {
          db: {
            url: databaseURL,
          },
        },
      });

      await prisma.$connect();
      await prisma.$disconnect();
      
      console.log('✅ Conexão com o banco de dados estabelecida com sucesso!');
      return true;
    } catch (error) {
      console.error('❌ Erro ao conectar com o banco de dados:', error);
      return false;
    }
  }

  /**
   * Executa migrações do banco de dados
   */
  async runMigrations(): Promise<boolean> {
    try {
      const { execSync } = require('child_process');
      
      // Obter URL do banco
      const databaseURL = await this.getDatabaseURL();
      
      // Definir a URL do banco como variável de ambiente
      process.env.DATABASE_URL = databaseURL;
      
      console.log('🔄 Executando migrações do Prisma...');
      
      // Executar migrações do Prisma
      execSync('npx prisma migrate deploy', { 
        stdio: 'inherit',
        env: { ...process.env, DATABASE_URL: databaseURL }
      });
      
      console.log('✅ Migrações executadas com sucesso!');
      return true;
    } catch (error) {
      console.error('❌ Erro ao executar migrações:', error);
      return false;
    }
  }

  /**
   * Gera o cliente Prisma com a configuração correta
   */
  async getPrismaClient() {
    const { PrismaClient } = require('@prisma/client');
    const databaseURL = await this.getDatabaseURL();
    
    return new PrismaClient({
      datasources: {
        db: {
          url: databaseURL,
        },
      },
      log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
    });
  }

  /**
   * Inicializa o serviço de banco de dados
   */
  async initialize(): Promise<void> {
    console.log('🔧 Inicializando serviço de banco de dados...');
    
    // Carregar configurações
    await this.loadConfig();
    
    // Testar conexão
    const isConnected = await this.testConnection();
    if (!isConnected) {
      throw new Error('Não foi possível conectar ao banco de dados');
    }
    
    console.log('✅ Serviço de banco de dados inicializado com sucesso');
  }
}

// Instância singleton
const databaseService = new DatabaseService();

export default databaseService; 