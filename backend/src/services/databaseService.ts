import encryptionService from './encryptionService';

interface DatabaseConfig {
  host: string;
  port: number;
  username: string;
  password: string;
  database: string;
}

class DatabaseService {
  private config: DatabaseConfig;

  constructor() {
    // Senha criptografada do banco RDS
    const encryptedPassword = 'f0ab35538ff8e4e7825363b2b5a348dc:654375d1c2216dc33d8c917db2ddc501';
    
    this.config = {
      host: process.env.DB_HOST || 'personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com',
      port: parseInt(process.env.DB_PORT || '3306'),
      username: process.env.DB_USERNAME || 'admin',
      password: process.env.DB_PASSWORD_ENCRYPTED ? 
        encryptionService.decryptDatabasePassword(process.env.DB_PASSWORD_ENCRYPTED) : 
        encryptionService.decryptDatabasePassword(encryptedPassword),
      database: process.env.DB_NAME || 'personal_trainer_db',
    };
  }

  /**
   * Obtém a URL de conexão do banco de dados
   */
  getDatabaseURL(): string {
    const { host, port, username, password, database } = this.config;
    
    // Codificar a senha para URL
    const encodedPassword = encodeURIComponent(password);
    
    return `mysql://${username}:${encodedPassword}@${host}:${port}/${database}`;
  }

  /**
   * Obtém a configuração do banco de dados
   */
  getDatabaseConfig(): DatabaseConfig {
    return { ...this.config };
  }

  /**
   * Criptografa e retorna a senha do banco
   */
  getEncryptedPassword(): string {
    return encryptionService.encryptDatabasePassword(this.config.password);
  }

  /**
   * Verifica se a conexão está configurada
   */
  isConfigured(): boolean {
    return !!(this.config.host && this.config.username && this.config.password);
  }

  /**
   * Testa a conexão com o banco de dados
   */
  async testConnection(): Promise<boolean> {
    try {
      const { PrismaClient } = require('@prisma/client');
      const prisma = new PrismaClient({
        datasources: {
          db: {
            url: this.getDatabaseURL(),
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
      
      // Definir a URL do banco como variável de ambiente
      process.env.DATABASE_URL = this.getDatabaseURL();
      
      // Executar migrações do Prisma
      execSync('npx prisma migrate deploy', { 
        stdio: 'inherit',
        env: { ...process.env, DATABASE_URL: this.getDatabaseURL() }
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
  getPrismaClient() {
    const { PrismaClient } = require('@prisma/client');
    
    return new PrismaClient({
      datasources: {
        db: {
          url: this.getDatabaseURL(),
        },
      },
      log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
    });
  }
}

// Instância singleton
const databaseService = new DatabaseService();

export default databaseService; 