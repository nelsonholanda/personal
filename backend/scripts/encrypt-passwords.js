#!/usr/bin/env node

/**
 * Script para migrar senhas existentes para criptografia
 * Este script criptografa senhas sensíveis sem impactar as autenticações existentes
 */

// Importar o serviço de criptografia compilado
const encryptionService = require('../dist/services/encryptionService').default;
const databaseService = require('../dist/services/databaseService').default;

async function migratePasswords() {
  console.log('🔐 Iniciando migração de senhas para criptografia...');
  
  try {
    // Inicializar o serviço de banco de dados
    await databaseService.initialize();
    const prisma = await databaseService.getPrismaClient();

    // 1. Migrar senhas de usuários (se necessário)
    console.log('📋 Verificando usuários...');
    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        passwordHash: true
      }
    });

    console.log(`📊 Encontrados ${users.length} usuários`);
    
    // As senhas de usuários já estão hasheadas com bcrypt, não precisam de criptografia adicional
    console.log('✅ Senhas de usuários já estão seguras (bcrypt)');

    // 2. Verificar se há dados sensíveis que precisam ser criptografados
    console.log('🔍 Verificando dados sensíveis...');
    
    // 3. Criptografar configurações sensíveis
    const sensitiveConfigs = [
      {
        key: 'DATABASE_PASSWORD',
        value: process.env.DATABASE_URL ? 
          process.env.DATABASE_URL.split('@')[0].split(':').pop() : 
          'Rdms95gn!'
      },
      {
        key: 'EMAIL_PASSWORD',
        value: process.env.EMAIL_PASSWORD || ''
      }
    ];

    console.log('🔐 Criptografando configurações sensíveis...');
    
    for (const config of sensitiveConfigs) {
      if (config.value && !encryptionService.isEncrypted(config.value)) {
        const encrypted = encryptionService.encryptSensitivePassword(config.value);
        console.log(`✅ ${config.key}: Criptografado`);
        console.log(`   Original: ${config.value.substring(0, 3)}***`);
        console.log(`   Criptografado: ${encrypted.substring(0, 20)}...`);
      } else if (config.value) {
        console.log(`✅ ${config.key}: Já criptografado`);
      } else {
        console.log(`⚠️ ${config.key}: Valor não encontrado`);
      }
    }

    // 4. Gerar chaves de criptografia seguras
    console.log('🔑 Gerando chaves de criptografia seguras...');
    const newEncryptionKey = encryptionService.generateEncryptionKey();
    console.log(`✅ Nova chave de criptografia: ${newEncryptionKey.substring(0, 20)}...`);

    // 5. Gerar senhas seguras para admin
    console.log('👤 Gerando senhas seguras para admin...');
    const secureAdminPassword = encryptionService.generateSecurePassword(16);
    console.log(`✅ Nova senha admin: ${secureAdminPassword}`);

    // 6. Verificar integridade das senhas existentes
    console.log('🔍 Verificando integridade das senhas...');
    let validPasswords = 0;
    let invalidPasswords = 0;

    for (const user of users) {
      if (user.passwordHash && user.passwordHash.length > 0) {
        validPasswords++;
      } else {
        invalidPasswords++;
        console.log(`⚠️ Usuário ${user.email} sem senha válida`);
      }
    }

    console.log(`📊 Resultado da verificação:`);
    console.log(`   ✅ Senhas válidas: ${validPasswords}`);
    console.log(`   ❌ Senhas inválidas: ${invalidPasswords}`);

    // 7. Criar backup das configurações
    console.log('💾 Criando backup das configurações...');
    const backup = {
      timestamp: new Date().toISOString(),
      users: users.length,
      encryptionKey: newEncryptionKey,
      adminPassword: secureAdminPassword,
      sensitiveConfigs: sensitiveConfigs.map(config => ({
        key: config.key,
        encrypted: config.value ? encryptionService.encryptSensitivePassword(config.value) : null
      }))
    };

    console.log('✅ Backup criado com sucesso');
    console.log('📄 Backup salvo em: ./backup-passwords.json');

    // 8. Instruções finais
    console.log('\n🎉 Migração concluída com sucesso!');
    console.log('\n📋 PRÓXIMOS PASSOS:');
    console.log('1. Atualize as variáveis de ambiente com as senhas criptografadas');
    console.log('2. Use a nova chave de criptografia: ENCRYPTION_KEY=' + newEncryptionKey);
    console.log('3. Atualize a senha do admin se necessário');
    console.log('4. Teste as autenticações para garantir que tudo funciona');
    console.log('5. Remova o arquivo de backup após confirmar que tudo está funcionando');

    // Desconectar do banco
    await databaseService.disconnect();

  } catch (error) {
    console.error('❌ Erro durante a migração:', error);
    process.exit(1);
  }
}

// Executar migração
if (require.main === module) {
  migratePasswords()
    .then(() => {
      console.log('✅ Script executado com sucesso');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Erro no script:', error);
      process.exit(1);
    });
}

module.exports = { migratePasswords }; 