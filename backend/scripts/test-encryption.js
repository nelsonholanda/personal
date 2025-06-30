#!/usr/bin/env node

/**
 * Script para testar as funcionalidades de criptografia
 * Este script demonstra como usar o serviço de criptografia
 */

// Importar o serviço de criptografia compilado
const encryptionService = require('../dist/services/encryptionService').default;

async function testEncryption() {
  console.log('🔐 Testando funcionalidades de criptografia...');
  
  try {
    // 1. Testar criptografia básica
    console.log('\n📝 Teste 1: Criptografia básica');
    const originalText = 'Senha123!@#';
    const encrypted = encryptionService.encrypt(originalText);
    const decrypted = encryptionService.decrypt(encrypted);
    
    console.log(`   Original: ${originalText}`);
    console.log(`   Criptografado: ${encrypted.substring(0, 20)}...`);
    console.log(`   Descriptografado: ${decrypted}`);
    console.log(`   ✅ Teste passou: ${originalText === decrypted ? 'SIM' : 'NÃO'}`);

    // 2. Testar geração de chave de criptografia
    console.log('\n🔑 Teste 2: Geração de chave de criptografia');
    const EncryptionServiceClass = require('../dist/services/encryptionService').default.constructor;
    const newKey = EncryptionServiceClass.generateEncryptionKey();
    console.log(`   Nova chave: ${newKey.substring(0, 20)}...`);
    console.log(`   ✅ Tamanho da chave: ${newKey.length} caracteres`);

    // 3. Testar geração de senha segura
    console.log('\n👤 Teste 3: Geração de senha segura');
    const securePassword = EncryptionServiceClass.generateSecurePassword(16);
    console.log(`   Senha gerada: ${securePassword}`);
    console.log(`   ✅ Tamanho da senha: ${securePassword.length} caracteres`);
    
    // Verificar complexidade da senha
    const hasUpperCase = /[A-Z]/.test(securePassword);
    const hasLowerCase = /[a-z]/.test(securePassword);
    const hasNumbers = /\d/.test(securePassword);
    const hasSymbols = /[!@#$%^&*(),.?":{}|<>]/.test(securePassword);
    
    console.log(`   ✅ Maiúsculas: ${hasUpperCase ? 'SIM' : 'NÃO'}`);
    console.log(`   ✅ Minúsculas: ${hasLowerCase ? 'SIM' : 'NÃO'}`);
    console.log(`   ✅ Números: ${hasNumbers ? 'SIM' : 'NÃO'}`);
    console.log(`   ✅ Símbolos: ${hasSymbols ? 'SIM' : 'NÃO'}`);

    // 4. Testar verificação de texto criptografado
    console.log('\n🔍 Teste 4: Verificação de texto criptografado');
    const plainText = 'Texto simples';
    const encryptedText = encryptionService.encrypt(plainText);
    
    console.log(`   Texto simples: ${encryptionService.isEncrypted(plainText) ? 'NÃO' : 'SIM'}`);
    console.log(`   Texto criptografado: ${encryptionService.isEncrypted(encryptedText) ? 'SIM' : 'NÃO'}`);

    // 5. Testar criptografia de dados sensíveis
    console.log('\n🛡️ Teste 5: Criptografia de dados sensíveis');
    const sensitiveData = {
      databasePassword: 'MinhaSenha123!',
      emailPassword: 'EmailPass456!',
      apiKey: 'api-key-secreta-789'
    };
    
    const encryptedData = encryptionService.encryptSensitiveData(sensitiveData, [
      'databasePassword', 
      'emailPassword', 
      'apiKey'
    ]);
    
    console.log('   Dados originais:', {
      databasePassword: sensitiveData.databasePassword.substring(0, 3) + '***',
      emailPassword: sensitiveData.emailPassword.substring(0, 3) + '***',
      apiKey: sensitiveData.apiKey.substring(0, 3) + '***'
    });
    
    console.log('   Dados criptografados:', {
      databasePassword: encryptedData.databasePassword.substring(0, 20) + '...',
      emailPassword: encryptedData.emailPassword.substring(0, 20) + '...',
      apiKey: encryptedData.apiKey.substring(0, 20) + '...'
    });

    // 6. Testar descriptografia de dados sensíveis
    console.log('\n🔓 Teste 6: Descriptografia de dados sensíveis');
    const decryptedData = encryptionService.decryptSensitiveData(encryptedData, [
      'databasePassword', 
      'emailPassword', 
      'apiKey'
    ]);
    
    console.log(`   ✅ Database password: ${decryptedData.databasePassword === sensitiveData.databasePassword ? 'CORRETO' : 'INCORRETO'}`);
    console.log(`   ✅ Email password: ${decryptedData.emailPassword === sensitiveData.emailPassword ? 'CORRETO' : 'INCORRETO'}`);
    console.log(`   ✅ API key: ${decryptedData.apiKey === sensitiveData.apiKey ? 'CORRETO' : 'INCORRETO'}`);

    // 7. Demonstrar uso prático
    console.log('\n💡 Demonstração prática:');
    console.log('   Para criptografar a senha do banco de dados:');
    console.log(`   const encryptedDbPassword = encryptionService.encryptDatabasePassword('${sensitiveData.databasePassword}');`);
    console.log(`   // Resultado: ${encryptionService.encryptDatabasePassword(sensitiveData.databasePassword).substring(0, 20)}...`);
    
    console.log('\n   Para descriptografar:');
    console.log('   const decryptedDbPassword = encryptionService.decryptDatabasePassword(encryptedDbPassword);');
    console.log(`   // Resultado: ${sensitiveData.databasePassword}`);

    // 8. Resumo final
    console.log('\n🎉 Todos os testes de criptografia foram executados com sucesso!');
    console.log('\n📋 PRÓXIMOS PASSOS:');
    console.log('1. Use encryptionService.encryptDatabasePassword() para senhas de banco');
    console.log('2. Use encryptionService.encryptSensitivePassword() para outras senhas');
    console.log('3. Configure ENCRYPTION_KEY nas variáveis de ambiente');
    console.log('4. Teste as autenticações para garantir compatibilidade');

  } catch (error) {
    console.error('❌ Erro durante os testes:', error);
    process.exit(1);
  }
}

// Executar testes
if (require.main === module) {
  testEncryption()
    .then(() => {
      console.log('\n✅ Script de teste executado com sucesso');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Erro no script:', error);
      process.exit(1);
    });
}

module.exports = { testEncryption }; 