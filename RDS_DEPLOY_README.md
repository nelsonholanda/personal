# Deploy NH Personal Trainer com RDS MySQL

Este guia explica como fazer o deploy da aplicação NH Personal Trainer usando Amazon RDS MySQL em vez do MySQL local.

## 🔧 Configurações Necessárias

### 1. Configurar Variáveis de Ambiente

Copie o arquivo de exemplo e configure suas variáveis:

```bash
cp env.example .env
nano .env
```

#### Opção A: Usando AWS Secrets Manager (Recomendado)

```env
# Configurações do AWS Secrets Manager
AWS_SECRET_NAME=rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811
AWS_REGION=us-east-2

# Configurações do JWT
JWT_SECRET=your-jwt-secret-key-here
JWT_ACCESS_TOKEN_SECRET=your-access-token-secret-here
JWT_REFRESH_TOKEN_SECRET=your-refresh-token-secret-here

# Ambiente
NODE_ENV=production
PORT=3001
FRONTEND_URL=http://localhost:3000
```

#### Opção B: Usando Variáveis de Ambiente Diretas

```env
# Configurações do RDS MySQL
RDS_HOST=your-rds-endpoint.amazonaws.com
RDS_PORT=3306
RDS_USERNAME=admin
RDS_PASSWORD=your-rds-password
RDS_DATABASE=personal_trainer_db

# Configurações do JWT
JWT_SECRET=your-jwt-secret-key-here
JWT_ACCESS_TOKEN_SECRET=your-access-token-secret-here
JWT_REFRESH_TOKEN_SECRET=your-refresh-token-secret-here

# Ambiente
NODE_ENV=production
PORT=3001
FRONTEND_URL=http://localhost:3000
```

### 2. Configurar AWS Secrets Manager (Opcional)

Se você escolher usar o AWS Secrets Manager, configure o secret com a seguinte estrutura JSON:

```json
{
  "host": "your-rds-endpoint.amazonaws.com",
  "port": 3306,
  "username": "admin",
  "password": "your-rds-password",
  "database": "personal_trainer_db"
}
```

## 🚀 Deploy na EC2

### 1. Preparar a EC2

Certifique-se de que sua instância EC2 tem:
- Docker instalado
- Docker Compose instalado
- AWS CLI configurado (se usar Secrets Manager)
- Permissões para acessar RDS

### 2. Executar o Deploy

```bash
# Tornar o script executável
chmod +x deploy-ec2-rds.sh

# Executar o deploy
./deploy-ec2-rds.sh
```

### 3. Verificar o Deploy

```bash
# Verificar status dos containers
docker ps

# Verificar logs
docker-compose logs -f

# Testar health check
curl http://localhost:3001/health
```

## 🔍 Troubleshooting

### Problemas Comuns

#### 1. Erro de Conexão com RDS

**Sintoma:** Containers reiniciando constantemente

**Solução:**
```bash
# Verificar logs do backend
docker-compose logs backend

# Verificar conectividade com RDS
telnet your-rds-endpoint.amazonaws.com 3306
```

#### 2. Erro de AWS Secrets Manager

**Sintoma:** "Falha ao carregar configurações do banco"

**Solução:**
```bash
# Verificar se AWS CLI está configurado
aws sts get-caller-identity

# Verificar se o secret existe
aws secretsmanager describe-secret --secret-id your-secret-name
```

#### 3. Erro de Build

**Sintoma:** "Cannot find module '/app/dist/index.js'"

**Solução:**
```bash
# Testar build localmente
./test-backend-build.sh

# Verificar se o Prisma client foi gerado
docker run --rm personal-backend ls -la /app/dist/
```

### Comandos Úteis

```bash
# Parar todos os serviços
docker-compose down

# Reiniciar apenas o backend
docker-compose restart backend

# Ver logs em tempo real
docker-compose logs -f backend

# Entrar no container do backend
docker-compose exec backend sh

# Testar conexão com banco dentro do container
docker-compose exec backend npx prisma db pull
```

## 📊 Monitoramento

### Health Checks

A aplicação expõe endpoints de health check:

- **Backend:** `http://localhost:3001/health`
- **Frontend:** `http://localhost:3000`

### Logs

Os logs são gerenciados pelo Docker Compose:

```bash
# Ver todos os logs
docker-compose logs

# Ver logs de um serviço específico
docker-compose logs backend

# Ver logs em tempo real
docker-compose logs -f
```

## 🔒 Segurança

### Recomendações

1. **Use AWS Secrets Manager** para armazenar credenciais
2. **Configure Security Groups** do RDS para permitir apenas a EC2
3. **Use IAM Roles** em vez de credenciais hardcoded
4. **Configure SSL/TLS** para conexões com RDS
5. **Use VPC** para isolamento de rede

### Configuração de Security Groups

Configure o Security Group do RDS para permitir conexões apenas da EC2:

```
Type: MySQL/Aurora
Protocol: TCP
Port: 3306
Source: Security Group da EC2
```

## 📝 Próximos Passos

1. **Configurar domínio** e SSL
2. **Configurar backup automático** do RDS
3. **Configurar monitoramento** com CloudWatch
4. **Configurar alertas** para downtime
5. **Configurar CI/CD** para deploys automáticos

## 🆘 Suporte

Se encontrar problemas:

1. Verifique os logs: `docker-compose logs`
2. Teste a conectividade com RDS
3. Verifique as variáveis de ambiente
4. Consulte a documentação do AWS RDS 