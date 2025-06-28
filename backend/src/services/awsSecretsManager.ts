import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';
import { KMSClient, DecryptCommand } from '@aws-sdk/client-kms';

interface DatabaseSecrets {
  host: string;
  port: number;
  username: string;
  password: string;
  database: string;
}

interface JWTSecrets {
  accessTokenSecret: string;
  refreshTokenSecret: string;
}

class AWSSecretsManager {
  private secretsManagerClient: SecretsManagerClient;
  private kmsClient: KMSClient;
  private region: string;

  constructor() {
    this.region = process.env.AWS_REGION || 'us-east-1';
    
    this.secretsManagerClient = new SecretsManagerClient({
      region: this.region,
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
      },
    });

    this.kmsClient = new KMSClient({
      region: this.region,
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
      },
    });
  }

  /**
   * Obtém segredos do AWS Secrets Manager
   */
  async getSecret(secretName: string): Promise<any> {
    try {
      const command = new GetSecretValueCommand({
        SecretId: secretName,
      });

      const response = await this.secretsManagerClient.send(command);
      
      if (response.SecretString) {
        return JSON.parse(response.SecretString);
      } else if (response.SecretBinary) {
        // Para segredos binários (criptografados com KMS)
        const decryptedSecret = await this.decryptSecret(response.SecretBinary);
        return JSON.parse(decryptedSecret);
      }

      throw new Error('Secret not found or invalid format');
    } catch (error) {
      console.error('Error fetching secret from AWS Secrets Manager:', error);
      throw error;
    }
  }

  /**
   * Descriptografa segredos usando AWS KMS
   */
  private async decryptSecret(encryptedSecret: Uint8Array): Promise<string> {
    try {
      const command = new DecryptCommand({
        CiphertextBlob: encryptedSecret,
      });

      const response = await this.kmsClient.send(command);
      
      if (response.Plaintext) {
        return new TextDecoder().decode(response.Plaintext);
      }

      throw new Error('Failed to decrypt secret');
    } catch (error) {
      console.error('Error decrypting secret with KMS:', error);
      throw error;
    }
  }

  /**
   * Obtém configurações do banco de dados
   */
  async getDatabaseSecrets(): Promise<DatabaseSecrets> {
    const secretName = process.env.AWS_DATABASE_SECRET_NAME || 'nh-personal/database';
    const secrets = await this.getSecret(secretName);
    
    return {
      host: secrets.host,
      port: parseInt(secrets.port) || 3306,
      username: secrets.username,
      password: secrets.password,
      database: secrets.database,
    };
  }

  /**
   * Obtém segredos JWT
   */
  async getJWTSecrets(): Promise<JWTSecrets> {
    const secretName = process.env.AWS_JWT_SECRET_NAME || 'nh-personal/jwt';
    const secrets = await this.getSecret(secretName);
    
    return {
      accessTokenSecret: secrets.accessTokenSecret,
      refreshTokenSecret: secrets.refreshTokenSecret,
    };
  }

  /**
   * Constrói a URL de conexão do banco de dados
   */
  async getDatabaseURL(): Promise<string> {
    const dbSecrets = await this.getDatabaseSecrets();
    
    return `mysql://${dbSecrets.username}:${encodeURIComponent(dbSecrets.password)}@${dbSecrets.host}:${dbSecrets.port}/${dbSecrets.database}`;
  }

  /**
   * Verifica se as credenciais AWS estão configuradas
   */
  isConfigured(): boolean {
    return !!(process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY);
  }

  /**
   * Fallback para configurações locais quando AWS não está disponível
   */
  getLocalDatabaseURL(): string {
    return process.env.DATABASE_URL || 'mysql://root:password@localhost:3306/personal_trainer_db';
  }

  /**
   * Fallback para JWT secrets locais
   */
  getLocalJWTSecrets(): JWTSecrets {
    return {
      accessTokenSecret: process.env.JWT_ACCESS_TOKEN_SECRET || 'your-access-token-secret',
      refreshTokenSecret: process.env.JWT_REFRESH_TOKEN_SECRET || 'your-refresh-token-secret',
    };
  }
}

// Instância singleton
const awsSecretsManager = new AWSSecretsManager();

export default awsSecretsManager; 