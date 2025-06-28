# NH-Personal - Documentação dos Scripts

Documentação completa dos scripts de instalação, configuração e manutenção do sistema NH-Personal.

## 📋 Visão Geral

Este projeto inclui vários scripts para automatizar a instalação, configuração e manutenção do sistema NH-Personal, configurado para usar RDS AWS como banco de dados.

## 🗄️ Configuração do RDS

### Configurações Atuais
- **Host**: `personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com`
- **Porta**: `3306`
- **Usuário**: `root`
- **Senha**: `rootpassword`
- **Banco**: `personal_trainer_db`
- **Região**: `us-east-2`
- **Secret Name**: `rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811`

## 📁 Scripts Disponíveis

### 1. `install-dependencies.sh` - Instalação Completa

**Descrição**: Script principal para instalação completa do sistema em servidores Linux.

**Funcionalidades**:
- ✅ Detecção automática do sistema operacional (Ubuntu, Debian, CentOS, Amazon Linux)
- ✅ Instalação de dependências básicas
- ✅ Instalação do Docker e Docker Compose
- ✅ Instalação do Node.js 18
- ✅ Instalação do cliente MySQL (para conexão com RDS)
- ✅ Instalação do AWS CLI v2
- ✅ Configuração do Nginx
- ✅ Configuração do firewall
- ✅ Criação de serviços systemd
- ✅ Configuração de variáveis de ambiente
- ✅ Configuração de logrotate
- ✅ Configuração de monitoramento
- ✅ **Não instala MySQL local** (usa RDS AWS)

**Uso**:
```bash
# Executar como root
sudo ./install-dependencies.sh
```

**Compatibilidade**:
- Ubuntu 18.04+
- Debian 9+
- CentOS 7+
- Amazon Linux 2
- RHEL 7+

### 2. `aws-userdata.sh` - User Data para EC2

**Descrição**: Script otimizado para uso no User Data de instâncias EC2 AWS.

**Funcionalidades**:
- ✅ Instalação automatizada em instâncias EC2
- ✅ Configuração para RDS AWS
- ✅ Logs detalhados em `/var/log/user-data.log`
- ✅ Configuração de serviços systemd
- ✅ Monitoramento automático
- ✅ **Usa RDS AWS em vez de MySQL local**

**Uso**:
```bash
# Copie o conteúdo para o User Data da instância EC2
# Ou execute diretamente na instância
sudo ./aws-userdata.sh
```

**Configurações Automáticas**:
- Cria diretório `/opt/nh-personal`
- Configura arquivo `.env` com RDS
- Cria serviços systemd
- Configura Nginx
- Configura firewall
- Configura monitoramento

### 3. `init-database.sh` - Inicialização do Banco RDS

**Descrição**: Script para inicializar o banco de dados RDS AWS.

**Funcionalidades**:
- ✅ Teste de conexão com RDS
- ✅ Criação do banco de dados
- ✅ Execução de migrações Prisma
- ✅ Inserção de dados iniciais
- ✅ Verificação de integridade
- ✅ Criação de usuários administradores

**Uso**:
```bash
# Execute após a instalação
sudo ./init-database.sh
```

**Dados Iniciais Criados**:
- Usuário admin: `admin@nhpersonal.com`
- Usuário nholanda: `nholanda@nhpersonal.com`
- Senha: `rdms95gn`
- Métodos de pagamento padrão
- Planos de pagamento padrão
- Exercícios padrão

### 4. `test-rds-connection.sh` - Teste de Conexão RDS

**Descrição**: Script para testar a conectividade com o RDS AWS.

**Funcionalidades**:
- ✅ Teste de conectividade de rede
- ✅ Teste de conexão MySQL
- ✅ Verificação de tabelas
- ✅ Verificação de usuários
- ✅ Teste de performance
- ✅ Status dos serviços

**Uso**:
```bash
# Teste a conexão com RDS
./test-rds-connection.sh
```

**Testes Realizados**:
- Ping para o host RDS
- Conectividade na porta 3306
- Conexão MySQL
- Acesso ao banco específico
- Contagem de tabelas
- Contagem de usuários
- Tempo de resposta

## 🚀 Processo de Instalação

### Opção 1: Instalação Automatizada (Recomendada)

1. **Execute o script de instalação**:
```bash
sudo ./install-dependencies.sh
```

2. **Inicialize o banco de dados**:
```bash
sudo ./init-database.sh
```

3. **Teste a conexão**:
```bash
./test-rds-connection.sh
```

4. **Inicie os serviços**:
```bash
sudo systemctl start nh-personal-backend nh-personal-frontend
sudo systemctl enable nh-personal-backend nh-personal-frontend
```

### Opção 2: User Data EC2

1. **Configure o User Data** da instância EC2 com o conteúdo de `aws-userdata.sh`

2. **Após o boot da instância**, execute:
```bash
sudo ./init-database.sh
sudo systemctl start nh-personal-backend nh-personal-frontend
```

## 🔧 Configuração Manual

### Variáveis de Ambiente

O arquivo `.env` é criado automaticamente com as seguintes configurações:

```env
# Server Configuration
NODE_ENV=production
PORT=3001
FRONTEND_URL=http://localhost:3000

# Database Configuration (RDS AWS)
DATABASE_URL=mysql://root:rootpassword@personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com:3306/personal_trainer_db

# AWS Configuration
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key

# AWS Secrets Manager Configuration
AWS_DATABASE_SECRET_NAME=rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811
AWS_JWT_SECRET_NAME=nh-personal/jwt
```

### Serviços Systemd

Os seguintes serviços são criados:

#### `nh-personal-backend.service`
```ini
[Unit]
Description=NH-Personal Backend API
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/nh-personal/backend
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

#### `nh-personal-frontend.service`
```ini
[Unit]
Description=NH-Personal Frontend
After=network.target nh-personal-backend.service
Wants=nh-personal-backend.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/nh-personal/frontend
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

## 📊 Monitoramento

### Script de Monitoramento

O script `/opt/nh-personal/monitor.sh` é executado automaticamente a cada 5 minutos via crontab.

**Verificações Realizadas**:
- Status dos serviços systemd
- Conexão com RDS
- Uso de disco
- Uso de memória

**Logs**: `/opt/nh-personal/logs/monitor.log`

### Comandos de Monitoramento

```bash
# Verificar status dos serviços
sudo systemctl status nh-personal-backend nh-personal-frontend nginx

# Ver logs em tempo real
sudo journalctl -u nh-personal-backend -f
sudo journalctl -u nh-personal-frontend -f

# Verificar logs do monitoramento
tail -f /opt/nh-personal/logs/monitor.log

# Testar conexão RDS
./test-rds-connection.sh
```

## 🔐 Segurança

### Configurações de Segurança

- **Firewall configurado** para portas necessárias
- **Permissões restritas** no arquivo `.env` (600)
- **Usuário root** para serviços (pode ser alterado)
- **Rate limiting** configurado no Nginx
- **Headers de segurança** com Helmet.js

### Portas Abertas

- **22**: SSH
- **80**: HTTP
- **443**: HTTPS
- **3000**: Frontend
- **3001**: Backend

## 🐛 Troubleshooting

### Problemas Comuns

#### 1. Erro de Conexão com RDS

```bash
# Teste a conectividade
./test-rds-connection.sh

# Verifique as configurações
cat /opt/nh-personal/.env | grep DATABASE_URL

# Teste manual
mysql -h personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com -u root -p
```

#### 2. Serviços Não Iniciam

```bash
# Verifique os logs
sudo journalctl -u nh-personal-backend -n 50
sudo journalctl -u nh-personal-frontend -n 50

# Verifique as permissões
sudo chown -R root:root /opt/nh-personal
sudo chmod 600 /opt/nh-personal/.env

# Verifique se o Node.js está instalado
node --version
npm --version
```

#### 3. Erro de Migração Prisma

```bash
# Execute as migrações manualmente
cd /opt/nh-personal/backend
export DATABASE_URL="mysql://root:rootpassword@personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com:3306/personal_trainer_db"
npx prisma migrate deploy
npx prisma generate
```

#### 4. Nginx Não Funciona

```bash
# Verifique a configuração
sudo nginx -t

# Verifique o status
sudo systemctl status nginx

# Reinicie o serviço
sudo systemctl restart nginx
```

### Logs Importantes

- **User Data**: `/var/log/user-data.log`
- **Serviços**: `journalctl -u <service-name>`
- **Nginx**: `/var/log/nginx/`
- **Monitoramento**: `/opt/nh-personal/logs/monitor.log`

## 📚 Comandos Úteis

### Gestão de Serviços

```bash
# Iniciar serviços
sudo systemctl start nh-personal-backend nh-personal-frontend

# Parar serviços
sudo systemctl stop nh-personal-backend nh-personal-frontend

# Reiniciar serviços
sudo systemctl restart nh-personal-backend nh-personal-frontend

# Verificar status
sudo systemctl status nh-personal-backend nh-personal-frontend

# Habilitar serviços
sudo systemctl enable nh-personal-backend nh-personal-frontend
```

### Gestão do Banco de Dados

```bash
# Conectar ao RDS
mysql -h personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com -u root -p

# Verificar tabelas
mysql -h personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com -u root -p personal_trainer_db -e "SHOW TABLES;"

# Verificar usuários
mysql -h personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com -u root -p personal_trainer_db -e "SELECT id, name, email, role FROM users;"
```

### Gestão de Logs

```bash
# Ver logs do sistema
sudo journalctl -f

# Ver logs específicos
sudo journalctl -u nh-personal-backend -f
sudo journalctl -u nh-personal-frontend -f

# Limpar logs antigos
sudo journalctl --vacuum-time=7d
```

## 🔄 Atualizações

### Atualizar o Sistema

```bash
# Atualizar dependências
sudo ./install-dependencies.sh

# Reiniciar serviços
sudo systemctl restart nh-personal-backend nh-personal-frontend
```

### Atualizar Banco de Dados

```bash
# Executar novas migrações
cd /opt/nh-personal/backend
npx prisma migrate deploy
npx prisma generate
```

## 📞 Suporte

Para suporte técnico:
- **Email**: suporte@nhpersonal.com
- **Documentação**: Consulte `README.md`
- **API**: Consulte `API_DOCUMENTATION.md`

---

**NH-Personal Scripts** - Automatizando a instalação e configuração do sistema! 🚀 