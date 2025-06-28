import * as crypto from 'crypto';

class EncryptionService {
  private algorithm = 'aes-256-cbc';
  private secretKey: string;

  constructor() {
    // Usar uma chave secreta do ambiente ou gerar uma padrão
    this.secretKey = process.env.ENCRYPTION_KEY || 'nh-personal-encryption-key-2024';
    
    // Garantir que a chave tenha 32 bytes (256 bits)
    if (this.secretKey.length < 32) {
      this.secretKey = this.secretKey.padEnd(32, '0');
    } else if (this.secretKey.length > 32) {
      this.secretKey = this.secretKey.substring(0, 32);
    }
  }

  /**
   * Criptografa uma string
   */
  encrypt(text: string): string {
    try {
      const iv = crypto.randomBytes(16);
      const cipher = crypto.createCipher(this.algorithm, this.secretKey);
      
      let encrypted = cipher.update(text, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      
      return iv.toString('hex') + ':' + encrypted;
    } catch (error) {
      console.error('Erro ao criptografar:', error);
      throw new Error('Falha na criptografia');
    }
  }

  /**
   * Descriptografa uma string
   */
  decrypt(encryptedText: string): string {
    try {
      const textParts = encryptedText.split(':');
      const iv = Buffer.from(textParts.shift()!, 'hex');
      const encryptedData = textParts.join(':');
      
      const decipher = crypto.createDecipher(this.algorithm, this.secretKey);
      
      let decrypted = decipher.update(encryptedData, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      
      return decrypted;
    } catch (error) {
      console.error('Erro ao descriptografar:', error);
      throw new Error('Falha na descriptografia');
    }
  }

  /**
   * Criptografa a senha do banco de dados
   */
  encryptDatabasePassword(password: string): string {
    return this.encrypt(password);
  }

  /**
   * Descriptografa a senha do banco de dados
   */
  decryptDatabasePassword(encryptedPassword: string): string {
    return this.decrypt(encryptedPassword);
  }

  /**
   * Gera uma chave de criptografia segura
   */
  static generateEncryptionKey(): string {
    return crypto.randomBytes(32).toString('hex');
  }

  /**
   * Verifica se uma string está criptografada
   */
  isEncrypted(text: string): boolean {
    return text.includes(':') && text.split(':')[0].length === 32;
  }
}

// Instância singleton
const encryptionService = new EncryptionService();

export default encryptionService; 