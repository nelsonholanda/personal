#!/bin/bash

# NH-Personal - Script de Instalação de Dependências
# Compatível com: Ubuntu, Debian, CentOS, Amazon Linux, RHEL
# Versão: 2.0.0
# Usando RDS AWS para banco de dados

set -e  # Para o script se houver erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Função para detectar o sistema operacional
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        OS=SuSE
    elif [ -f /etc/redhat-release ]; then
        OS=RedHat
        VER=$(cat /etc/redhat-release | sed 's/.*release \([0-9.]*\).*/\1/')
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    log "Sistema operacional detectado: $OS $VER"
}

# Função para atualizar o sistema
update_system() {
    log "Atualizando sistema operacional..."
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            apt-get update -y
            apt-get upgrade -y
            ;;
        *"CentOS"*|*"Red Hat"*|*"Amazon Linux"*|*"RHEL"*)
            yum update -y
            ;;
        *)
            error "Sistema operacional não suportado: $OS"
            exit 1
            ;;
    esac
}

# Função para instalar dependências básicas
install_basic_deps() {
    log "Instalando dependências básicas..."
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
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
            ;;
        *"CentOS"*|*"Red Hat"*|*"Amazon Linux"*|*"RHEL"*)
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
            ;;
    esac
}

# Função para instalar Docker
install_docker() {
    log "Instalando Docker..."
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            # Remover versões antigas
            apt-get remove -y docker docker-engine docker.io containerd runc || true
            
            # Adicionar repositório oficial
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            apt-get update -y
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # Adicionar usuário ao grupo docker
            usermod -aG docker $SUDO_USER || usermod -aG docker ubuntu || usermod -aG docker ec2-user || true
            ;;
        *"CentOS"*|*"Red Hat"*|*"Amazon Linux"*|*"RHEL"*)
            # Instalar Docker via yum
            yum install -y docker
            
            # Iniciar e habilitar Docker
            systemctl start docker
            systemctl enable docker
            
            # Adicionar usuário ao grupo docker
            usermod -aG docker $SUDO_USER || usermod -aG docker centos || usermod -aG docker ec2-user || true
            ;;
    esac
    
    # Verificar instalação
    docker --version
    docker-compose --version || docker compose version
}

# Função para instalar Node.js
install_nodejs() {
    log "Instalando Node.js 18.x..."
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            # Adicionar repositório NodeSource
            curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
            apt-get install -y nodejs
            ;;
        *"CentOS"*|*"Red Hat"*|*"Amazon Linux"*|*"RHEL"*)
            # Adicionar repositório NodeSource
            curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
            yum install -y nodejs
            ;;
    esac
    
    # Verificar instalação
    node --version
    npm --version
    
    # Instalar ferramentas globais úteis
    npm install -g npm@latest
    npm install -g nodemon typescript ts-node
}

# Função para instalar cliente MySQL (apenas para conexão com RDS)
install_mysql_client() {
    log "Instalando cliente MySQL para conexão com RDS..."
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            apt-get install -y mysql-client
            ;;
        *"CentOS"*|*"Red Hat"*|*"Amazon Linux"*|*"RHEL"*)
            yum install -y mysql
            ;;
    esac
    
    # Verificar instalação
    mysql --version
}

# Função para instalar AWS CLI
install_aws_cli() {
    log "Instalando AWS CLI v2..."
    
    # Baixar e instalar AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    
    # Limpar arquivos temporários
    rm -rf awscliv2.zip aws/
    
    # Verificar instalação
    aws --version
}

# Função para configurar firewall
configure_firewall() {
    log "Configurando firewall..."
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            # Instalar UFW se não estiver instalado
            apt-get install -y ufw
            
            # Configurar regras básicas
            ufw --force enable
            ufw default deny incoming
            ufw default allow outgoing
            ufw allow ssh
            ufw allow 22
            ufw allow 80
            ufw allow 443
            ufw allow 3000
            ufw allow 3001
            ;;
        *"CentOS"*|*"Red Hat"*|*"Amazon Linux"*|*"RHEL"*)
            # Configurar firewalld
            systemctl start firewalld
            systemctl enable firewalld
            
            # Configurar regras básicas
            firewall-cmd --permanent --add-service=ssh
            firewall-cmd --permanent --add-port=22/tcp
            firewall-cmd --permanent --add-port=80/tcp
            firewall-cmd --permanent --add-port=443/tcp
            firewall-cmd --permanent --add-port=3000/tcp
            firewall-cmd --permanent --add-port=3001/tcp
            firewall-cmd --reload
            ;;
    esac
}

# Função para configurar variáveis de ambiente
setup_environment() {
    log "Configurando variáveis de ambiente..."
    
    # Criar diretório do projeto
    mkdir -p /opt/nh-personal
    cd /opt/nh-personal
    
    # Criar arquivo .env básico com RDS
    cat > .env << EOF
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

# JWT Configuration (Local fallback)
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
    
    # Definir permissões
    chmod 600 .env
}

# Função para configurar systemd services
setup_services() {
    log "Configurando serviços systemd..."
    
    # Criar serviço para o backend (sem dependência do MySQL local)
    cat > /etc/systemd/system/nh-personal-backend.service << EOF
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
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Criar serviço para o frontend
    cat > /etc/systemd/system/nh-personal-frontend.service << EOF
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
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Recarregar systemd
    systemctl daemon-reload
}

# Função para configurar Nginx
setup_nginx() {
    log "Configurando Nginx..."
    
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            apt-get install -y nginx
            ;;
        *"CentOS"*|*"Red Hat"*|*"Amazon Linux"*|*"RHEL"*)
            yum install -y nginx
            ;;
    esac
    
    # Configurar Nginx
    cat > /etc/nginx/sites-available/nh-personal << EOF
server {
    listen 80;
    server_name _;
    
    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:3001/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # Habilitar site
    ln -sf /etc/nginx/sites-available/nh-personal /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Testar configuração
    nginx -t
    
    # Iniciar e habilitar Nginx
    systemctl start nginx
    systemctl enable nginx
}

# Função para configurar logrotate
setup_logrotate() {
    log "Configurando logrotate..."
    
    cat > /etc/logrotate.d/nh-personal << EOF
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
}

# Função para configurar monitoramento básico
setup_monitoring() {
    log "Configurando monitoramento básico..."
    
    # Instalar htop e outras ferramentas
    case $OS in
        *"Ubuntu"*|*"Debian"*)
            apt-get install -y htop iotop nethogs
            ;;
        *"CentOS"*|*"Red Hat"*|*"Amazon Linux"*|*"RHEL"*)
            yum install -y htop iotop nethogs
            ;;
    esac
    
    # Criar script de monitoramento
    cat > /opt/nh-personal/monitor.sh << 'EOF'
#!/bin/bash

# Script de monitoramento básico para NH-Personal

LOG_FILE="/opt/nh-personal/logs/monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Verificar serviços
check_service() {
    local service=$1
    if systemctl is-active --quiet $service; then
        echo "[$DATE] ✅ $service está rodando" >> $LOG_FILE
    else
        echo "[$DATE] ❌ $service não está rodando" >> $LOG_FILE
        systemctl restart $service
    fi
}

# Verificar uso de disco
check_disk() {
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $usage -gt 80 ]; then
        echo "[$DATE] ⚠️ Uso de disco alto: ${usage}%" >> $LOG_FILE
    fi
}

# Verificar uso de memória
check_memory() {
    local usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ $usage -gt 80 ]; then
        echo "[$DATE] ⚠️ Uso de memória alto: ${usage}%" >> $LOG_FILE
    fi
}

# Verificar conexão com RDS
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
    
    if mysql -h "$rds_host" -u "$rds_user" -p"$rds_password" -e "SELECT 1;" >/dev/null 2>&1; then
        echo "[$DATE] ✅ Conexão com RDS OK" >> $LOG_FILE
    else
        echo "[$DATE] ❌ Erro na conexão com RDS" >> $LOG_FILE
    fi
}

# Executar verificações
check_service nh-personal-backend
check_service nh-personal-frontend
check_service nginx
check_rds_connection
check_disk
check_memory
EOF
    
    chmod +x /opt/nh-personal/monitor.sh
    
    # Adicionar ao crontab
    echo "*/5 * * * * /opt/nh-personal/monitor.sh" | crontab -
}

# Função para criar diretórios e permissões
setup_directories() {
    log "Criando diretórios e configurando permissões..."
    
    # Criar estrutura de diretórios
    mkdir -p /opt/nh-personal/{backend,frontend,logs,database}
    mkdir -p /opt/nh-personal/backend/{src,dist}
    mkdir -p /opt/nh-personal/frontend/{src,dist}
    
    # Definir permissões
    chown -R root:root /opt/nh-personal
    chmod -R 755 /opt/nh-personal
    chmod 600 /opt/nh-personal/.env
}

# Função para instalar dependências do projeto
install_project_deps() {
    log "Instalando dependências do projeto..."
    
    cd /opt/nh-personal
    
    # Clonar projeto (se necessário)
    if [ ! -d ".git" ]; then
        log "Projeto não encontrado. Execute 'git clone' manualmente ou copie os arquivos."
    fi
    
    # Instalar dependências do backend
    if [ -f "backend/package.json" ]; then
        log "Instalando dependências do backend..."
        cd backend
        npm install --production
        npm run build || true
        cd ..
    fi
    
    # Instalar dependências do frontend
    if [ -f "frontend/package.json" ]; then
        log "Instalando dependências do frontend..."
        cd frontend
        npm install --production
        npm run build || true
        cd ..
    fi
}

# Função para testar conexão com RDS
test_rds_connection() {
    log "Testando conexão com RDS..."
    
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
    
    if mysql -h "$rds_host" -u "$rds_user" -p"$rds_password" -e "SELECT 1;" >/dev/null 2>&1; then
        log "✅ Conexão com RDS estabelecida com sucesso"
    else
        warn "⚠️ Não foi possível conectar ao RDS. Verifique as credenciais e configurações de rede."
    fi
}

# Função para mostrar informações finais
show_final_info() {
    log "Instalação concluída com sucesso!"
    echo ""
    echo "🎉 NH-Personal instalado com sucesso!"
    echo ""
    echo "📋 Informações do sistema:"
    echo "   Sistema Operacional: $OS $VER"
    echo "   Diretório do projeto: /opt/nh-personal"
    echo "   Arquivo de configuração: /opt/nh-personal/.env"
    echo ""
    echo "🔧 Serviços configurados:"
    echo "   - nh-personal-backend.service"
    echo "   - nh-personal-frontend.service"
    echo "   - nginx.service"
    echo ""
    echo "🗄️ Banco de dados:"
    echo "   - Tipo: RDS AWS"
    echo "   - Configuração: AWS Secrets Manager"
    echo "   - Secret Name: rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811"
    echo ""
    echo "🌐 URLs de acesso:"
    echo "   - Frontend: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'localhost'):80"
    echo "   - Backend API: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'localhost'):3001"
    echo "   - Health Check: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'localhost'):3001/health"
    echo ""
    echo "👤 Usuário administrador:"
    echo "   Email: admin@nhpersonal.com"
    echo "   Usuário: nholanda"
    echo "   Senha: rdms95gn"
    echo ""
    echo "🔐 Configurações de segurança:"
    echo "   - Senhas criptografadas com bcrypt"
    echo "   - AWS Secrets Manager configurado"
    echo "   - Firewall configurado"
    echo "   - Rate limiting ativo"
    echo "   - RDS AWS para banco de dados"
    echo ""
    echo "📊 Comandos úteis:"
    echo "   - Verificar status: systemctl status nh-personal-backend nh-personal-frontend"
    echo "   - Ver logs: journalctl -u nh-personal-backend -f"
    echo "   - Reiniciar serviços: systemctl restart nh-personal-backend nh-personal-frontend"
    echo "   - Monitoramento: /opt/nh-personal/monitor.sh"
    echo "   - Testar RDS: ./test-rds-connection.sh [SECRET_NAME]"
    echo ""
    echo "⚠️ Próximos passos:"
    echo "   1. Configure as variáveis AWS no arquivo .env"
    echo "   2. Copie os arquivos do projeto para /opt/nh-personal"
    echo "   3. Execute: systemctl start nh-personal-backend nh-personal-frontend"
    echo "   4. Configure SSL se necessário"
    echo "   5. Verifique a conexão com RDS"
    echo ""
}

# Função principal
main() {
    log "Iniciando instalação do NH-Personal..."
    
    # Verificar se é root
    if [ "$EUID" -ne 0 ]; then
        error "Este script deve ser executado como root"
        exit 1
    fi
    
    # Detectar sistema operacional
    detect_os
    
    # Atualizar sistema
    update_system
    
    # Instalar dependências básicas
    install_basic_deps
    
    # Instalar Docker
    install_docker
    
    # Instalar Node.js
    install_nodejs
    
    # Instalar cliente MySQL
    install_mysql_client
    
    # Instalar AWS CLI
    install_aws_cli
    
    # Configurar firewall
    configure_firewall
    
    # Configurar ambiente
    setup_environment
    
    # Configurar diretórios
    setup_directories
    
    # Configurar Nginx
    setup_nginx
    
    # Configurar serviços systemd
    setup_services
    
    # Configurar logrotate
    setup_logrotate
    
    # Configurar monitoramento
    setup_monitoring
    
    # Instalar dependências do projeto
    install_project_deps
    
    # Testar conexão com RDS
    test_rds_connection
    
    # Mostrar informações finais
    show_final_info
    
    log "Instalação concluída!"
}

# Executar função principal
main "$@" 