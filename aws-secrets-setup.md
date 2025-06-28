# AWS Secrets Manager Setup - NH-Personal

## 🔐 Configuração do AWS Secrets Manager

Este documento explica como configurar o AWS Secrets Manager para o sistema NH-Personal.

## 📋 Pré-requisitos

1. **Conta AWS** ativa
2. **IAM User** com permissões para Secrets Manager e KMS
3. **AWS CLI** configurado localmente

## 🚀 Configuração Passo a Passo

### 1. Criar IAM User

Crie um usuário IAM com as seguintes políticas:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            "Resource": [
                "arn:aws:secretsmanager:*:*:secret:nh-personal/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        }
    ]
}
```

### 2. Criar Secrets no AWS Secrets Manager

#### Database Secret

```bash
aws secretsmanager create-secret \
    --name "nh-personal/database" \
    --description "Database credentials for NH-Personal application" \
    --secret-string '{
        "host": "your-database-host",
        "port": 3306,
        "username": "your-database-username",
        "password": "your-database-password",
        "database": "personal_trainer_db"
    }'
```

#### JWT Secret

```bash
aws secretsmanager create-secret \
    --name "nh-personal/jwt" \
    --description "JWT secrets for NH-Personal application" \
    --secret-string '{
        "accessTokenSecret": "your-super-secret-access-token-key-change-in-production",
        "refreshTokenSecret": "your-super-secret-refresh-token-key-change-in-production"
    }'
```

### 3. Configurar Variáveis de Ambiente

Adicione as seguintes variáveis ao seu arquivo `.env`:

```env
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key

# AWS Secrets Manager Configuration
AWS_DATABASE_SECRET_NAME=nh-personal/database
AWS_JWT_SECRET_NAME=nh-personal/jwt
```

### 4. Testar Configuração

Para testar se a configuração está funcionando:

```bash
# Testar conexão com AWS
aws sts get-caller-identity

# Testar acesso aos secrets
aws secretsmanager get-secret-value --secret-id nh-personal/database
aws secretsmanager get-secret-value --secret-id nh-personal/jwt
```

## 🔒 Segurança Adicional

### Usar KMS para Criptografia

Para maior segurança, você pode usar AWS KMS para criptografar os secrets:

1. **Criar chave KMS:**
```bash
aws kms create-key \
    --description "NH-Personal Secrets Encryption Key" \
    --key-usage ENCRYPT_DECRYPT
```

2. **Criar secret criptografado:**
```bash
aws secretsmanager create-secret \
    --name "nh-personal/database" \
    --description "Database credentials for NH-Personal application" \
    --secret-string '{
        "host": "your-database-host",
        "port": 3306,
        "username": "your-database-username",
        "password": "your-database-password",
        "database": "personal_trainer_db"
    }' \
    --kms-key-id alias/your-kms-key-alias
```

### Rotação de Credenciais

Configure rotação automática de credenciais:

```bash
# Criar função Lambda para rotação
aws secretsmanager create-secret \
    --name "nh-personal/database" \
    --description "Database credentials with rotation" \
    --secret-string '{
        "host": "your-database-host",
        "port": 3306,
        "username": "your-database-username",
        "password": "your-database-password",
        "database": "personal_trainer_db"
    }' \
    --rotation-rules '{
        "AutomaticallyAfterDays": 30
    }'
```

## 🧪 Testando Localmente

### 1. Configurar AWS CLI

```bash
aws configure
```

### 2. Testar no Código

```javascript
// Teste simples
const awsSecretsManager = require('./services/awsSecretsManager');

async function testSecrets() {
    try {
        const dbSecrets = await awsSecretsManager.getDatabaseSecrets();
        console.log('Database secrets loaded:', dbSecrets);
        
        const jwtSecrets = await awsSecretsManager.getJWTSecrets();
        console.log('JWT secrets loaded:', jwtSecrets);
    } catch (error) {
        console.error('Error loading secrets:', error);
    }
}

testSecrets();
```

## 🚨 Troubleshooting

### Erro: Access Denied
- Verifique as permissões IAM
- Confirme se o usuário tem acesso aos secrets
- Verifique se os nomes dos secrets estão corretos

### Erro: Secret Not Found
- Confirme se o secret foi criado corretamente
- Verifique o nome do secret
- Confirme a região AWS

### Erro: KMS Decryption Failed
- Verifique se a chave KMS existe
- Confirme as permissões de decriptação
- Verifique se a chave está na região correta

## 📊 Monitoramento

### CloudWatch Logs

Configure logs para monitorar acesso aos secrets:

```bash
# Habilitar logs de auditoria
aws secretsmanager update-secret \
    --secret-id nh-personal/database \
    --description "Database credentials with audit logging"
```

### Alertas

Configure alertas para:
- Tentativas de acesso não autorizado
- Falhas de rotação de credenciais
- Uso excessivo de secrets

## 🔄 Backup e Recuperação

### Backup de Secrets

```bash
# Fazer backup de um secret
aws secretsmanager get-secret-value \
    --secret-id nh-personal/database \
    --query SecretString \
    --output text > backup-database-secret.json
```

### Recuperação

```bash
# Restaurar secret
aws secretsmanager create-secret \
    --name "nh-personal/database-backup" \
    --secret-string file://backup-database-secret.json
```

## 💰 Custos

### Secrets Manager Pricing
- **$0.40 por secret por mês**
- **$0.05 por 10.000 chamadas de API**

### KMS Pricing
- **$1.00 por mês por chave**
- **$0.03 por 10.000 operações de criptografia**

## 📞 Suporte

Para problemas com AWS Secrets Manager:
- **AWS Support**: https://aws.amazon.com/support/
- **Documentação**: https://docs.aws.amazon.com/secretsmanager/
- **Fórum**: https://forums.aws.amazon.com/

---

**NH-Personal v2.0.0** - Segurança Avançada com AWS 