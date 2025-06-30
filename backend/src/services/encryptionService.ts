import * as crypto from 'crypto';

class EncryptionService {
  private algorithm = 'aes-256-cbc'; // Algoritmo mais compatível
  private secretKey: string;
  private keyLength = 32; // 256 bits
  private ivLength = 16; // 128 bits

  constructor() {
    // Usar uma chave secreta do ambiente ou gerar uma padrão
    this.secretKey = process.env.ENCRYPTION_KEY || 'nh-personal-encryption-key-2024';
    
    // Garantir que a chave tenha o tamanho correto
    this.secretKey = this.normalizeKey(this.secretKey);
  }

  /**
   * Normaliza a chave para ter o tamanho correto
   */
  private normalizeKey(key: string): string {
    if (key.length < this.keyLength) {
      return key.padEnd(this.keyLength, '0');
    } else if (key.length > this.keyLength) {
      return key.substring(0, this.keyLength);
    }
    return key;
  }

  /**
   * Criptografa uma string usando AES-256-CBC
   */
  encrypt(text: string): string {
    try {
      const iv = crypto.randomBytes(this.ivLength);
      const cipher = crypto.createCipher(this.algorithm, this.secretKey);
      
      let encrypted = cipher.update(text, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      
      // Formato: iv:encrypted
      return iv.toString('hex') + ':' + encrypted;
    } catch (error) {
      console.error('Erro ao criptografar:', error);
      throw new Error('Falha na criptografia');
    }
  }

  /**
   * Descriptografa uma string usando AES-256-CBC
   */
  decrypt(encryptedText: string): string {
    try {
      const parts = encryptedText.split(':');
      if (parts.length !== 2) {
        throw new Error('Formato de texto criptografado inválido');
      }
      
      const iv = Buffer.from(parts[0], 'hex');
      const encryptedData = parts[1];
      
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
   * Criptografa senhas sensíveis para armazenamento
   */
  encryptSensitivePassword(password: string): string {
    return this.encrypt(password);
  }

  /**
   * Descriptografa senhas sensíveis
   */
  decryptSensitivePassword(encryptedPassword: string): string {
    return this.decrypt(encryptedPassword);
  }

  /**
   * Gera uma chave de criptografia segura
   */
  static generateEncryptionKey(): string {
    return crypto.randomBytes(32).toString('hex');
  }

  /**
   * Gera uma senha segura
   */
  static generateSecurePassword(length: number = 16): string {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
    let password = '';
    
    // Garantir pelo menos um de cada tipo
    password += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[crypto.randomInt(26)]; // Maiúscula
    password += 'abcdefghijklmnopqrstuvwxyz'[crypto.randomInt(26)]; // Minúscula
    password += '0123456789'[crypto.randomInt(10)]; // Número
    password += '!@#$%^&*'[crypto.randomInt(8)]; // Símbolo
    
    // Completar o resto da senha
    for (let i = 4; i < length; i++) {
      password += charset[crypto.randomInt(charset.length)];
    }
    
    // Embaralhar a senha
    return password.split('').sort(() => 0.5 - Math.random()).join('');
  }

  /**
   * Verifica se uma string está criptografada
   */
  isEncrypted(text: string): boolean {
    try {
      const parts = text.split(':');
      return parts.length === 2 && parts[0].length === 32;
    } catch {
      return false;
    }
  }

  /**
   * Criptografa dados sensíveis em objetos
   */
  encryptSensitiveData(data: any, fields: string[]): any {
    const encrypted = { ...data };
    
    for (const field of fields) {
      if (encrypted[field] && typeof encrypted[field] === 'string') {
        encrypted[field] = this.encrypt(encrypted[field]);
      }
    }
    
    return encrypted;
  }

  /**
   * Descriptografa dados sensíveis em objetos
   */
  decryptSensitiveData(data: any, fields: string[]): any {
    const decrypted = { ...data };
    
    for (const field of fields) {
      if (decrypted[field] && typeof decrypted[field] === 'string' && this.isEncrypted(decrypted[field])) {
        decrypted[field] = this.decrypt(decrypted[field]);
      }
    }
    
    return decrypted;
  }
}

// Instância singleton
const encryptionService = new EncryptionService();

export default encryptionService; 