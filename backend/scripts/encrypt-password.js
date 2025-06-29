const crypto = require('crypto');

// Configuração de criptografia
const algorithm = 'aes-256-cbc';
const secretKey = process.env.ENCRYPTION_KEY || 'nh-personal-encryption-key-2024';

// Garantir que a chave tenha 32 bytes (256 bits)
let key = secretKey;
if (key.length < 32) {
  key = key.padEnd(32, '0');
} else if (key.length > 32) {
  key = key.substring(0, 32);
}

// Senha do banco de dados
const databasePassword = 'Rdms95gn!';

// Função para criptografar
function encrypt(text) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipher(algorithm, key);
  
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  return iv.toString('hex') + ':' + encrypted;
}

// Função para descriptografar
function decrypt(encryptedText) {
  const textParts = encryptedText.split(':');
  const iv = Buffer.from(textParts.shift(), 'hex');
  const encryptedData = textParts.join(':');
  
  const decipher = crypto.createDecipher(algorithm, key);
  
  let decrypted = decipher.update(encryptedData, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  
  return decrypted;
}

// Criptografar a senha
const encryptedPassword = encrypt(databasePassword);

console.log('🔐 Configuração de Criptografia');
console.log('================================');
console.log(`Chave de criptografia: ${secretKey}`);
console.log(`Senha original: ${databasePassword}`);
console.log(`Senha criptografada: ${encryptedPassword}`);

// Testar descriptografia
const decryptedPassword = decrypt(encryptedPassword);
console.log('✅ Teste de descriptografia:');
console.log(`Senha descriptografada: ${decryptedPassword}`);

if (databasePassword === decryptedPassword) {
  console.log('🎉 Criptografia funcionando corretamente!');
} else {
  console.log('❌ Erro na criptografia!');
}

// Gerar variáveis de ambiente
console.log('📝 Variáveis de ambiente para .env:');
console.log('====================================');
console.log(`ENCRYPTION_KEY=${secretKey}`);
console.log(`DB_HOST=personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com`);
console.log(`DB_PORT=3306`);
console.log(`DB_USERNAME=admin`);
console.log(`DB_PASSWORD_ENCRYPTED=${encryptedPassword}`);
console.log(`DB_NAME=personal_trainer_db`);
console.log('');

// Gerar configuração para o databaseService
console.log('🔧 Configuração para databaseService.ts:');
console.log('=========================================');
console.log(`const encryptedPassword = '${encryptedPassword}';`);
console.log('');

console.log('✅ Script executado com sucesso!');
console.log('💡 Copie a senha criptografada e atualize o databaseService.ts'); 