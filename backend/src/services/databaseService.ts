import { PrismaClient } from '@prisma/client';
import encryptionService from './encryptionService';

interface DatabaseConfig {
  host: string;
  port: number;
  username: string;
  password: string;
  database: string;
}

class DatabaseService {
  private config: DatabaseConfig | null = null;
  private prismaClient: PrismaClient | null = null;

  constructor() {
    this.initialize();
  }

  /**
   * Inicializa a configuração do banco de dados
   */
  async initialize(): Promise<void> {
    try {
      // Configuração do banco de dados
      this.config = {
        host: process.env.RDS_HOST || process.env.DB_HOST || 'localhost',
        port: parseInt(process.env.RDS_PORT || process.env.DB_PORT || '3306'),
        username: process.env.RDS_USERNAME || process.env.DB_USERNAME || 'root',
        password: this.decryptPassword(process.env.RDS_PASSWORD || process.env.DB_PASSWORD || ''),
        database: process.env.RDS_DATABASE || process.env.DB_DATABASE || 'personal_trainer_db'
      };

      // Validar configuração
      if (!this.config.host || !this.config.username || !this.config.password || !this.config.database) {
        throw new Error('Configuração incompleta do banco de dados');
      }

      console.log('✅ Configuração do banco de dados carregada com sucesso');
    } catch (error) {
      console.error('❌ Erro ao inicializar configuração do banco:', error);
      throw error;
    }
  }

  /**
   * Descriptografa a senha do banco se estiver criptografada
   */
  private decryptPassword(password: string): string {
    try {
      if (encryptionService.isEncrypted(password)) {
        return encryptionService.decryptDatabasePassword(password);
      }
      return password;
    } catch (error) {
      console.warn('⚠️ Erro ao descriptografar senha, usando senha em texto plano');
      return password;
    }
  }

  /**
   * Obtém a configuração do banco de dados
   */
  getDatabaseConfig(): DatabaseConfig {
    if (!this.config) {
      throw new Error('Configuração do banco de dados não inicializada');
    }
    return this.config;
  }

  /**
   * Gera a URL de conexão do banco de dados
   */
  getDatabaseUrl(): string {
    if (!this.config) {
      throw new Error('Configuração do banco de dados não inicializada');
    }

    const { host, port, username, password, database } = this.config;
    
    // Codificar a senha para URL
    const encodedPassword = encodeURIComponent(password);
    
    return `mysql://${username}:${encodedPassword}@${host}:${port}/${database}`;
  }

  /**
   * Obtém o cliente Prisma
   */
  async getPrismaClient(): Promise<PrismaClient> {
    if (!this.prismaClient) {
      try {
        // Configurar variável de ambiente para o Prisma
        process.env.DATABASE_URL = this.getDatabaseUrl();
        
        this.prismaClient = new PrismaClient({
          log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
        });

        // Testar conexão
        await this.prismaClient.$connect();
        console.log('✅ Conexão com banco de dados estabelecida');
      } catch (error) {
        console.error('❌ Erro ao conectar com banco de dados:', error);
        throw error;
      }
    }

    return this.prismaClient;
  }

  /**
   * Testa a conexão com o banco de dados
   */
  async testConnection(): Promise<boolean> {
    try {
      const prisma = await this.getPrismaClient();
      await prisma.$queryRaw`SELECT 1`;
      return true;
    } catch (error) {
      console.error('❌ Teste de conexão falhou:', error);
      return false;
    }
  }

  /**
   * Executa migrações do banco de dados
   */
  async runMigrations(): Promise<void> {
    try {
      console.log('🔄 Executando migrações do banco de dados...');
      const { execSync } = require('child_process');
      execSync('npx prisma migrate deploy', { stdio: 'inherit' });
      console.log('✅ Migrações executadas com sucesso');
    } catch (error) {
      console.error('❌ Erro ao executar migrações:', error);
      throw error;
    }
  }

  /**
   * Verifica se a configuração está válida
   */
  isConfigured(): boolean {
    return !!(this.config?.host && this.config?.username && this.config?.password);
  }

  /**
   * Fecha a conexão com o banco de dados
   */
  async disconnect(): Promise<void> {
    if (this.prismaClient) {
      await this.prismaClient.$disconnect();
      this.prismaClient = null;
    }
  }

  /**
   * Criptografa uma senha para armazenamento seguro
   */
  encryptPassword(password: string): string {
    return encryptionService.encryptDatabasePassword(password);
  }
}

// Instância singleton
const databaseService = new DatabaseService();

export default databaseService; 