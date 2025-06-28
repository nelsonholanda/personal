import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

interface PasswordValidationResult {
  isValid: boolean;
  errors: string[];
}

class PasswordService {
  private readonly SALT_ROUNDS = 12;
  private readonly MIN_PASSWORD_LENGTH = 8;
  private readonly MAX_PASSWORD_HISTORY = 5;

  /**
   * Criptografa uma senha usando bcrypt
   */
  async hashPassword(password: string): Promise<string> {
    return await bcrypt.hash(password, this.SALT_ROUNDS);
  }

  /**
   * Verifica se uma senha corresponde ao hash
   */
  async verifyPassword(password: string, hash: string): Promise<boolean> {
    return await bcrypt.compare(password, hash);
  }

  /**
   * Valida uma nova senha
   */
  validatePassword(password: string): PasswordValidationResult {
    const errors: string[] = [];

    if (password.length < this.MIN_PASSWORD_LENGTH) {
      errors.push(`Senha deve ter pelo menos ${this.MIN_PASSWORD_LENGTH} caracteres`);
    }

    if (!/[A-Z]/.test(password)) {
      errors.push('Senha deve conter pelo menos uma letra maiúscula');
    }

    if (!/[a-z]/.test(password)) {
      errors.push('Senha deve conter pelo menos uma letra minúscula');
    }

    if (!/\d/.test(password)) {
      errors.push('Senha deve conter pelo menos um número');
    }

    if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
      errors.push('Senha deve conter pelo menos um caractere especial');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Verifica se a nova senha não foi usada recentemente
   */
  async isPasswordReused(userId: number, newPassword: string): Promise<boolean> {
    const passwordHistory = await prisma.passwordHistory.findMany({
      where: { userId },
      orderBy: { changedAt: 'desc' },
      take: this.MAX_PASSWORD_HISTORY
    });

    for (const history of passwordHistory) {
      const isMatch = await this.verifyPassword(newPassword, history.passwordHash);
      if (isMatch) {
        return true;
      }
    }

    return false;
  }

  /**
   * Atualiza a senha do usuário e salva no histórico
   */
  async updatePassword(userId: number, newPassword: string): Promise<void> {
    // Valida a nova senha
    const validation = this.validatePassword(newPassword);
    if (!validation.isValid) {
      throw new Error(`Senha inválida: ${validation.errors.join(', ')}`);
    }

    // Verifica se a senha não foi reutilizada
    const isReused = await this.isPasswordReused(userId, newPassword);
    if (isReused) {
      throw new Error('Nova senha não pode ser igual às últimas 5 senhas utilizadas');
    }

    // Criptografa a nova senha
    const hashedPassword = await this.hashPassword(newPassword);

    // Atualiza a senha do usuário
    await prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash: hashedPassword,
        passwordChangedAt: new Date(),
        passwordResetToken: null,
        passwordResetExpires: null
      }
    });

    // Salva no histórico de senhas
    await prisma.passwordHistory.create({
      data: {
        userId,
        passwordHash: hashedPassword
      }
    });
  }

  /**
   * Gera um token para reset de senha
   */
  generatePasswordResetToken(): string {
    return crypto.randomBytes(32).toString('hex');
  }

  /**
   * Criptografa o token de reset de senha
   */
  async hashPasswordResetToken(token: string): Promise<string> {
    return await bcrypt.hash(token, 10);
  }

  /**
   * Verifica se o token de reset de senha é válido
   */
  async verifyPasswordResetToken(token: string, hashedToken: string): Promise<boolean> {
    return await bcrypt.compare(token, hashedToken);
  }

  /**
   * Cria um token de reset de senha para o usuário
   */
  async createPasswordResetToken(email: string): Promise<string | null> {
    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      return null;
    }

    const resetToken = this.generatePasswordResetToken();
    const hashedToken = await this.hashPasswordResetToken(resetToken);

    // Token expira em 1 hora
    const resetExpires = new Date(Date.now() + 60 * 60 * 1000);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        passwordResetToken: hashedToken,
        passwordResetExpires: resetExpires
      }
    });

    return resetToken;
  }

  /**
   * Reseta a senha usando o token
   */
  async resetPasswordWithToken(token: string, newPassword: string): Promise<boolean> {
    const user = await prisma.user.findFirst({
      where: {
        passwordResetToken: { not: null },
        passwordResetExpires: { gt: new Date() }
      }
    });

    if (!user || !user.passwordResetToken) {
      return false;
    }

    // Verifica se o token é válido
    const isTokenValid = await this.verifyPasswordResetToken(token, user.passwordResetToken);
    if (!isTokenValid) {
      return false;
    }

    // Atualiza a senha
    await this.updatePassword(user.id, newPassword);

    return true;
  }

  /**
   * Força a mudança de senha na próxima sessão
   */
  async forcePasswordChange(userId: number): Promise<void> {
    await prisma.user.update({
      where: { id: userId },
      data: {
        passwordChangedAt: new Date(0) // Força mudança de senha
      }
    });
  }

  /**
   * Verifica se a senha precisa ser alterada
   */
  async isPasswordChangeRequired(userId: number): Promise<boolean> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { passwordChangedAt: true }
    });

    if (!user) {
      return false;
    }

    // Se passwordChangedAt é 1970-01-01, força mudança
    return user.passwordChangedAt.getTime() === 0;
  }

  /**
   * Gera uma senha aleatória segura
   */
  generateSecurePassword(length: number = 12): string {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
    let password = '';
    
    // Garante pelo menos um de cada tipo
    password += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[Math.floor(Math.random() * 26)]; // Maiúscula
    password += 'abcdefghijklmnopqrstuvwxyz'[Math.floor(Math.random() * 26)]; // Minúscula
    password += '0123456789'[Math.floor(Math.random() * 10)]; // Número
    password += '!@#$%^&*'[Math.floor(Math.random() * 8)]; // Especial

    // Completa o resto da senha
    for (let i = 4; i < length; i++) {
      password += charset[Math.floor(Math.random() * charset.length)];
    }

    // Embaralha a senha
    return password.split('').sort(() => Math.random() - 0.5).join('');
  }

  /**
   * Limpa tokens de reset expirados
   */
  async cleanupExpiredResetTokens(): Promise<void> {
    await prisma.user.updateMany({
      where: {
        passwordResetExpires: {
          lt: new Date()
        }
      },
      data: {
        passwordResetToken: null,
        passwordResetExpires: null
      }
    });
  }
}

export default new PasswordService(); 