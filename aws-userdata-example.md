# AWS User Data - Exemplo de Uso

## 🚀 Como Usar o Script no AWS User Data

### 1. Criar Instância EC2

1. Acesse o AWS Console
2. Vá para EC2 > Instâncias > Lançar instâncias
3. Configure a instância conforme necessário

### 2. Configurar User Data

Na seção "Configurar detalhes avançados", cole o seguinte script no campo "User data":

```bash
#!/bin/bash

# NH-Personal - AWS User Data Script
# Este script será executado automaticamente quando a instância iniciar

set -e

# Configurar log
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "🚀 Iniciando configuração da instância NH-Personal..."

# Atualizar sistema
yum update -y || apt-get update -y

# Instalar dependências básicas
if command -v yum &> /dev/null; then
    # Amazon Linux / CentOS
    yum install -y \
        curl \
        wget \
        git \
        unzip \
        gcc \
        gcc-c++ \
        make \
        python3 \
        python3-pip \
        vim \
        nano \
        htop \
        tree \
        jq \
        bc \
        uuid \
        epel-release
elif command -v apt-get &> /dev/null; then
    # Ubuntu / Debian
    apt-get install -y \
        curl \
        wget \
        git \
        unzip \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        python3 \
        python3-pip \
        vim \
        nano \
        htop \
        tree \
        jq \
        bc \
        uuid-runtime
fi

# Instalar Docker
if command -v yum &> /dev/null; then
    # Amazon Linux / CentOS
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
elif command -v apt-get &> /dev/null; then
    # Ubuntu / Debian
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    usermod -aG docker ubuntu
fi

# Instalar Node.js 18
if command -v yum &> /dev/null; then
    # Amazon Linux / CentOS
    curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
    yum install -y nodejs
elif command -v apt-get &> /dev/null; then
    # Ubuntu / Debian
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi

# Instalar AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws/

# Instalar MySQL
if command -v yum &> /dev/null; then
    # Amazon Linux / CentOS
    yum install -y mysql-server mysql
    systemctl start mysqld
    systemctl enable mysqld
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'rootpassword';"
    mysql -e "FLUSH PRIVILEGES;"
elif command -v apt-get &> /dev/null; then
    # Ubuntu / Debian
    apt-get install -y mysql-server mysql-client
    systemctl start mysql
    systemctl enable mysql
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'rootpassword';"
    mysql -e "FLUSH PRIVILEGES;"
fi

# Instalar Nginx
if command -v yum &> /dev/null; then
    yum install -y nginx
elif command -v apt-get &> /dev/null; then
    apt-get install -y nginx
fi

# Criar diretório do projeto
mkdir -p /opt/nh-personal/{backend,frontend,logs,database}
cd /opt/nh-personal

# Criar arquivo .env
cat > .env << 'EOF'
# NH-Personal Environment Variables

# Server Configuration
NODE_ENV=production
PORT=3001
FRONTEND_URL=http://localhost:3000

# Database Configuration
DATABASE_URL=mysql://root:rootpassword@localhost:3306/personal_trainer_db

# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key

# AWS Secrets Manager Configuration
AWS_DATABASE_SECRET_NAME=nh-personal/database
AWS_JWT_SECRET_NAME=nh-personal/jwt

# JWT Configuration
JWT_ACCESS_TOKEN_SECRET=your-super-secret-access-token-key-change-in-production
JWT_REFRESH_TOKEN_SECRET=your-super-secret-refresh-token-key-change-in-production
JWT_ACCESS_TOKEN_EXPIRES_IN=15m
JWT_REFRESH_TOKEN_EXPIRES_IN=7d

# Security Configuration
BCRYPT_SALT_ROUNDS=12
PASSWORD_MIN_LENGTH=8
PASSWORD_MAX_HISTORY=5
PASSWORD_RESET_TOKEN_EXPIRES_IN=3600000

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Production Configuration
ENABLE_COMPRESSION=true
ENABLE_HELMET=true
ENABLE_RATE_LIMIT=true
EOF

# Configurar Nginx
cat > /etc/nginx/sites-available/nh-personal << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:3001/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Habilitar site Nginx
ln -sf /etc/nginx/sites-available/nh-personal /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Configurar firewall
if command -v yum &> /dev/null; then
    # Amazon Linux / CentOS
    systemctl start firewalld
    systemctl enable firewalld
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-port=22/tcp
    firewall-cmd --permanent --add-port=80/tcp
    firewall-cmd --permanent --add-port=443/tcp
    firewall-cmd --permanent --add-port=3000/tcp
    firewall-cmd --permanent --add-port=3001/tcp
    firewall-cmd --permanent --add-port=3306/tcp
    firewall-cmd --reload
elif command -v apt-get &> /dev/null; then
    # Ubuntu / Debian
    apt-get install -y ufw
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 22
    ufw allow 80
    ufw allow 443
    ufw allow 3000
    ufw allow 3001
    ufw allow 3306
fi

# Criar banco de dados
mysql -u root -prootpassword -e "CREATE DATABASE IF NOT EXISTS personal_trainer_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Configurar serviços systemd
cat > /etc/systemd/system/nh-personal-backend.service << 'EOF'
[Unit]
Description=NH-Personal Backend API
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/nh-personal/backend
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm start
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/nh-personal-frontend.service << 'EOF'
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
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Recarregar systemd
systemctl daemon-reload

# Iniciar e habilitar serviços
systemctl start nginx
systemctl enable nginx

# Configurar logrotate
cat > /etc/logrotate.d/nh-personal << 'EOF'
/opt/nh-personal/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload nh-personal-backend
        systemctl reload nh-personal-frontend
    endscript
}
EOF

# Criar script de monitoramento
cat > /opt/nh-personal/monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/opt/nh-personal/logs/monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

check_service() {
    local service=$1
    if systemctl is-active --quiet $service; then
        echo "[$DATE] ✅ $service está rodando" >> $LOG_FILE
    else
        echo "[$DATE] ❌ $service não está rodando" >> $LOG_FILE
        systemctl restart $service
    fi
}

check_disk() {
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $usage -gt 80 ]; then
        echo "[$DATE] ⚠️ Uso de disco alto: ${usage}%" >> $LOG_FILE
    fi
}

check_memory() {
    local usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ $usage -gt 80 ]; then
        echo "[$DATE] ⚠️ Uso de memória alto: ${usage}%" >> $LOG_FILE
    fi
}

check_service nh-personal-backend
check_service nh-personal-frontend
check_service nginx
check_service mysql
check_disk
check_memory
EOF

chmod +x /opt/nh-personal/monitor.sh

# Adicionar monitoramento ao crontab
echo "*/5 * * * * /opt/nh-personal/monitor.sh" | crontab -

# Definir permissões
chown -R root:root /opt/nh-personal
chmod -R 755 /opt/nh-personal
chmod 600 /opt/nh-personal/.env

# Criar arquivo de informações
cat > /opt/nh-personal/INSTALACAO_INFO.txt << 'EOF'
🎉 NH-Personal instalado com sucesso!

📋 Informações do sistema:
   Diretório do projeto: /opt/nh-personal
   Arquivo de configuração: /opt/nh-personal/.env

🔧 Serviços configurados:
   - nh-personal-backend.service
   - nh-personal-frontend.service
   - nginx.service
   - mysql.service

🌐 URLs de acesso:
   - Frontend: http://[IP_PUBLICO]:80
   - Backend API: http://[IP_PUBLICO]:3001
   - Health Check: http://[IP_PUBLICO]:3001/health

👤 Usuário administrador:
   Email: admin@nhpersonal.com
   Usuário: nholanda
   Senha: rdms95gn

🔐 Configurações de segurança:
   - Senhas criptografadas com bcrypt
   - AWS Secrets Manager configurado
   - Firewall configurado
   - Rate limiting ativo

📊 Comandos úteis:
   - Verificar status: systemctl status nh-personal-backend nh-personal-frontend
   - Ver logs: journalctl -u nh-personal-backend -f
   - Reiniciar serviços: systemctl restart nh-personal-backend nh-personal-frontend
   - Monitoramento: /opt/nh-personal/monitor.sh

⚠️ Próximos passos:
   1. Configure as variáveis AWS no arquivo .env
   2. Copie os arquivos do projeto para /opt/nh-personal
   3. Execute: systemctl start nh-personal-backend nh-personal-frontend
   4. Configure SSL se necessário

📞 Suporte: suporte@nhpersonal.com
EOF

echo "✅ Configuração da instância concluída!"
echo "📋 Verifique /opt/nh-personal/INSTALACAO_INFO.txt para mais informações"
echo "🌐 Acesse: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'localhost')"
```

### 3. Configurar Security Group

Certifique-se de que o Security Group permite as seguintes portas:

- **22** (SSH)
- **80** (HTTP)
- **443** (HTTPS)
- **3000** (Frontend)
- **3001** (Backend)

### 4. Configurar IAM Role (Opcional)

Para usar AWS Secrets Manager, crie um IAM Role com as seguintes políticas:

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

### 5. Lançar a Instância

1. Clique em "Lançar instância"
2. Aguarde a instância inicializar
3. O script será executado automaticamente

### 6. Verificar Instalação

Após a inicialização, conecte-se via SSH e verifique:

```bash
# Verificar logs do User Data
tail -f /var/log/user-data.log

# Verificar status dos serviços
systemctl status nh-personal-backend nh-personal-frontend nginx mysql

# Verificar informações da instalação
cat /opt/nh-personal/INSTALACAO_INFO.txt

# Verificar IP público
curl -s http://169.254.169.254/latest/meta-data/public-ipv4
```

### 7. Próximos Passos

1. **Copiar arquivos do projeto**:
   ```bash
   # Via SCP
   scp -r ./backend ec2-user@[IP_PUBLICO]:/opt/nh-personal/
   scp -r ./frontend ec2-user@[IP_PUBLICO]:/opt/nh-personal/
   scp ./database/init.sql ec2-user@[IP_PUBLICO]:/opt/nh-personal/database/
   
   # Ou via Git
   cd /opt/nh-personal
   git clone https://github.com/seu-repo/nh-personal.git .
   ```

2. **Configurar variáveis de ambiente**:
   ```bash
   sudo nano /opt/nh-personal/.env
   # Configure AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY
   ```

3. **Instalar dependências e iniciar**:
   ```bash
   cd /opt/nh-personal/backend
   npm install
   npm run build
   
   cd /opt/nh-personal/frontend
   npm install
   npm run build
   
   # Iniciar serviços
   systemctl start nh-personal-backend nh-personal-frontend
   ```

4. **Acessar a aplicação**:
   - Frontend: `http://[IP_PUBLICO]`
   - Backend: `http://[IP_PUBLICO]:3001`
   - Health Check: `http://[IP_PUBLICO]:3001/health`

## 🔧 Configurações Avançadas

### Usar AWS Secrets Manager

1. **Criar secrets no AWS Secrets Manager**:
   ```bash
   aws secretsmanager create-secret \
       --name "nh-personal/database" \
       --secret-string '{
           "host": "localhost",
           "port": 3306,
           "username": "root",
           "password": "rootpassword",
           "database": "personal_trainer_db"
       }'
   ```

2. **Configurar IAM Role** (se não configurado):
   - Anexe o IAM Role à instância EC2
   - Ou configure credenciais AWS no arquivo `.env`

### Configurar SSL/HTTPS

```bash
# Instalar Certbot
sudo apt-get install certbot python3-certbot-nginx

# Configurar SSL
sudo certbot --nginx -d seu-dominio.com
```

### Configurar Backup Automático

```bash
# Criar script de backup
cat > /opt/nh-personal/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/nh-personal/backups"

mkdir -p $BACKUP_DIR

# Backup do banco
mysqldump -u root -prootpassword personal_trainer_db > $BACKUP_DIR/db_backup_$DATE.sql

# Backup dos arquivos
tar -czf $BACKUP_DIR/files_backup_$DATE.tar.gz /opt/nh-personal/

# Manter apenas os últimos 7 backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /opt/nh-personal/backup.sh

# Adicionar ao crontab (backup diário às 2h)
echo "0 2 * * * /opt/nh-personal/backup.sh" | crontab -
```

## 📊 Monitoramento

### CloudWatch (Opcional)

Configure CloudWatch para monitorar:

- **CPU Utilization**
- **Memory Utilization**
- **Disk Usage**
- **Network In/Out**

### Alertas

Configure alertas para:

- **CPU > 80%**
- **Memory > 80%**
- **Disk > 80%**
- **Serviços down**

## 🚨 Troubleshooting

### Verificar Logs

```bash
# Logs do User Data
tail -f /var/log/user-data.log

# Logs dos serviços
journalctl -u nh-personal-backend -f
journalctl -u nh-personal-frontend -f
journalctl -u nginx -f

# Logs de monitoramento
tail -f /opt/nh-personal/logs/monitor.log
```

### Problemas Comuns

1. **Serviços não iniciam**:
   ```bash
   # Verificar dependências
   cd /opt/nh-personal/backend
   npm install
   
   # Verificar configuração
   systemctl cat nh-personal-backend
   ```

2. **MySQL não conecta**:
   ```bash
   # Verificar status
   systemctl status mysql
   
   # Conectar manualmente
   mysql -u root -prootpassword
   ```

3. **Nginx não funciona**:
   ```bash
   # Verificar configuração
   nginx -t
   
   # Verificar logs
   tail -f /var/log/nginx/error.log
   ```

---

**NH-Personal v2.0.0** - AWS User Data Configuration 