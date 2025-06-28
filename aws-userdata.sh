#!/bin/bash

# NH-Personal - AWS User Data Script
# Para usar no User Data de instâncias EC2
# Compatível com: Amazon Linux 2, Ubuntu, CentOS
# Usando RDS AWS para banco de dados

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

# Instalar cliente MySQL (apenas para conexão com RDS)
if command -v yum &> /dev/null; then
    # Amazon Linux / CentOS
    yum install -y mysql
elif command -v apt-get &> /dev/null; then
    # Ubuntu / Debian
    apt-get install -y mysql-client
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

# Criar arquivo .env com configuração RDS
cat > .env << 'EOF'
# NH-Personal Environment Variables

# Server Configuration
NODE_ENV=production
PORT=3001
FRONTEND_URL=http://localhost:3000

# Database Configuration (RDS AWS) - Usando AWS Secrets Manager
# DATABASE_URL será configurado dinamicamente pelo backend usando AWS Secrets Manager
# Fallback para desenvolvimento local
DATABASE_URL=mysql://root:password@localhost:3306/personal_trainer_db

# AWS Configuration
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key

# AWS Secrets Manager Configuration
AWS_DATABASE_SECRET_NAME=rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811
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
fi

# Configurar serviços systemd (sem dependência do MySQL local)
cat > /etc/systemd/system/nh-personal-backend.service << 'EOF'
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

# Criar script de monitoramento (sem verificação do MySQL local)
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

check_rds_connection() {
    # Obter credenciais do AWS Secrets Manager se disponível
    local rds_host=""
    local rds_user=""
    local rds_password=""
    
    # Tentar obter do AWS Secrets Manager
    if command -v /usr/local/bin/aws &> /dev/null; then
        if /usr/local/bin/aws sts get-caller-identity &> /dev/null; then
            local secret_json
            if secret_json=$(/usr/local/bin/aws secretsmanager get-secret-value --secret-id "rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811" --region "us-east-2" --query 'SecretString' --output text 2>/dev/null); then
                rds_host=$(echo "$secret_json" | jq -r '.host // empty')
                rds_user=$(echo "$secret_json" | jq -r '.username // empty')
                rds_password=$(echo "$secret_json" | jq -r '.password // empty')
            fi
        fi
    fi
    
    # Fallback para variáveis de ambiente
    rds_host="${rds_host:-$RDS_HOST}"
    rds_user="${rds_user:-$RDS_USER}"
    rds_password="${rds_password:-$RDS_PASSWORD}"
    
    # Fallback final
    rds_host="${rds_host:-localhost}"
    rds_user="${rds_user:-root}"
    rds_password="${rds_password:-password}"
    
    # Testar conexão com RDS
    if mysql -h "$rds_host" -u "$rds_user" -p"$rds_password" -e "SELECT 1;" >/dev/null 2>&1; then
        echo "[$DATE] ✅ Conexão com RDS OK" >> $LOG_FILE
    else
        echo "[$DATE] ❌ Erro na conexão com RDS" >> $LOG_FILE
    fi
}

check_service nh-personal-backend
check_service nh-personal-frontend
check_service nginx
check_rds_connection
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

🗄️ Banco de dados:
   - Tipo: RDS AWS
   - Configuração: AWS Secrets Manager
   - Secret Name: rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811

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
   - RDS AWS para banco de dados

📊 Comandos úteis:
   - Verificar status: systemctl status nh-personal-backend nh-personal-frontend
   - Ver logs: journalctl -u nh-personal-backend -f
   - Reiniciar serviços: systemctl restart nh-personal-backend nh-personal-frontend
   - Monitoramento: /opt/nh-personal/monitor.sh
   - Testar RDS: mysql -h [HOST_DO_SECRET] -u [USER_DO_SECRET] -p

⚠️ Próximos passos:
   1. Configure as variáveis AWS no arquivo .env
   2. Copie os arquivos do projeto para /opt/nh-personal
   3. Execute: systemctl start nh-personal-backend nh-personal-frontend
   4. Configure SSL se necessário
   5. Verifique a conexão com RDS usando AWS Secrets Manager

📞 Suporte: suporte@nhpersonal.com
EOF

echo "✅ Configuração da instância concluída!"
echo "📋 Verifique /opt/nh-personal/INSTALACAO_INFO.txt para mais informações"
echo "🌐 Acesse: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'localhost')"
echo "🗄️ RDS configurado via AWS Secrets Manager" 