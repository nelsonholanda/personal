#!/bin/bash

# Script Completo de Deploy para Ubuntu EC2 - NH Personal Trainer
# Versão: 4.0.0 - Ubuntu Server

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Função para mostrar ajuda
show_help() {
    echo "🚀 Script de Deploy para Ubuntu EC2 - NH Personal Trainer"
    echo "========================================================"
    echo ""
    echo "Uso: $0 [OPÇÃO]"
    echo ""
    echo "Opções:"
    echo "  deploy     - Fazer deploy completo da aplicação"
    echo "  diagnose   - Executar diagnóstico completo"
    echo "  test       - Executar teste rápido"
    echo "  logs       - Mostrar logs dos containers"
    echo "  status     - Mostrar status dos containers"
    echo "  restart    - Reiniciar todos os containers"
    echo "  stop       - Parar todos os containers"
    echo "  cleanup    - Limpar containers e imagens antigas"
    echo "  backup     - Fazer backup do banco de dados"
    echo "  help       - Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 deploy     # Fazer deploy completo"
    echo "  $0 diagnose   # Verificar status da aplicação"
    echo "  $0 test       # Teste rápido"
    echo "  $0 logs       # Ver logs em tempo real"
    echo ""
}

# Função para verificar se é Ubuntu
check_ubuntu() {
    if ! grep -q "Ubuntu" /etc/os-release; then
        warning "Este script foi otimizado para Ubuntu. Outras distribuições podem não funcionar corretamente."
    fi
}

# Função para instalar dependências
install_dependencies() {
    log "📦 Instalando dependências do sistema..."
    
    # Atualizar sistema
    sudo apt update -y
    
    # Instalar dependências básicas
    sudo apt install -y git wget curl unzip jq software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    
    success "Dependências básicas instaladas"
}

# Função para instalar Docker
install_docker() {
    log "🐳 Instalando Docker..."
    
    if command -v docker &> /dev/null; then
        success "Docker já está instalado"
        return
    fi
    
    # Adicionar repositório oficial do Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Instalar Docker
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # Iniciar e habilitar Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Adicionar usuário ao grupo docker
    sudo usermod -aG docker $USER
    
    success "Docker instalado e configurado"
}

# Função para instalar Docker Compose
install_docker_compose() {
    log "📦 Instalando Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        success "Docker Compose já está instalado"
        return
    fi
    
    # Instalar Docker Compose
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Criar link simbólico
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    success "Docker Compose instalado"
}

# Função para configurar firewall
configure_firewall() {
    log "🔒 Configurando firewall..."
    
    # Instalar ufw se não estiver instalado
    if ! command -v ufw &> /dev/null; then
        sudo apt install -y ufw
    fi
    
    # Configurar regras
    sudo ufw allow 22/tcp    # SSH
    sudo ufw allow 80/tcp    # HTTP
    sudo ufw allow 443/tcp   # HTTPS
    sudo ufw allow 3000/tcp  # Frontend
    sudo ufw allow 3001/tcp  # Backend
    sudo ufw allow 3306/tcp  # MySQL
    
    # Habilitar firewall
    echo "y" | sudo ufw enable
    
    success "Firewall configurado"
}

# Função para configurar variáveis de ambiente
setup_environment() {
    log "⚙️ Configurando variáveis de ambiente..."
    
    # Backend .env
    cat > backend/.env <<EOF
ENCRYPTION_KEY=nh-personal-encryption-key-2024
DB_HOST=personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com
DB_PORT=3306
DB_USERNAME=admin
DB_PASSWORD_ENCRYPTED=f0ab35538ff8e4e7825363b2b5a348dc:654375d1c2216dc33d8c917db2ddc501
DB_NAME=personal_trainer_db
NODE_ENV=production
PORT=3001
JWT_ACCESS_TOKEN_SECRET=nh-personal-access-token-secret-2024
JWT_REFRESH_TOKEN_SECRET=nh-personal-refresh-token-secret-2024
AWS_REGION=us-east-2
AWS_SECRET_NAME=rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811
EOF

    # Frontend .env
    cat > frontend/.env <<EOF
REACT_APP_API_URL=http://localhost:3001/api
NODE_ENV=production
EOF

    # .env principal
    cat > .env <<EOF
# Database Configuration
MYSQL_ROOT_PASSWORD=nh-personal-root-2024
MYSQL_DATABASE=personal_trainer_db
MYSQL_USER=admin
MYSQL_PASSWORD=nh-personal-password-2024

# AWS Configuration
AWS_REGION=us-east-2
AWS_SECRET_NAME=rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811

# RDS Configuration (fallback)
RDS_HOST=personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com
RDS_PORT=3306
RDS_USERNAME=admin
RDS_PASSWORD=nh-personal-password-2024
RDS_DATABASE=personal_trainer_db
EOF

    success "Variáveis de ambiente configuradas"
}

# Função para fazer deploy
deploy_application() {
    log "🚀 Iniciando deploy da aplicação..."
    
    # Verificar se estamos no diretório correto
    if [ ! -f "docker-compose.yml" ]; then
        error "Arquivo docker-compose.yml não encontrado. Execute este script no diretório raiz do projeto."
    fi
    
    # Recarregar grupos do usuário
    log "🔄 Recarregando grupos do usuário..."
    newgrp docker
    
    # Parar containers existentes
    log "🛑 Parando containers existentes..."
    sudo docker-compose down --remove-orphans
    
    # Limpar imagens antigas
    log "🧹 Limpando imagens antigas..."
    sudo docker system prune -f
    
    # Construir e iniciar containers
    log "🐳 Construindo e iniciando containers..."
    sudo docker-compose up --build -d
    
    success "Containers iniciados"
    
    # Aguardar serviços estarem prontos
    log "⏳ Aguardando serviços estarem prontos..."
    sleep 30
    
    # Verificar se o backend está respondendo
    log "🔍 Verificando se o backend está respondendo..."
    for i in {1..10}; do
        if curl -f http://localhost:3001/health > /dev/null 2>&1; then
            success "Backend está respondendo"
            break
        else
            warning "Tentativa $i: Backend ainda não está respondendo..."
            sleep 10
        fi
    done
    
    # Executar migrações
    log "🗄️ Executando migrações do banco..."
    sudo docker-compose exec -T backend npx prisma migrate deploy
    
    success "Migrações executadas"
    
    # Criar usuário administrador
    log "👤 Criando usuário administrador..."
    sudo docker-compose exec -T backend node scripts/create-admin-user.js
    
    success "Usuário administrador criado"
    
    # Configurar logs
    log "📝 Configurando logs..."
    sudo mkdir -p /var/log/nh-personal
    sudo chown $USER:$USER /var/log/nh-personal
    
    # Mostrar informações finais
    show_deploy_info
}

# Função para mostrar informações do deploy
show_deploy_info() {
    # Obter IP público da instância
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")
    
    echo ""
    echo "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
    echo "=================================="
    echo "🌐 URLs da aplicação:"
    echo "   Frontend: http://$PUBLIC_IP:3000"
    echo "   Backend:  http://$PUBLIC_IP:3001"
    echo "   Health Check: http://$PUBLIC_IP:3001/health"
    echo ""
    echo "👤 Credenciais de Administrador:"
    echo "   Email: nholanda@nhpersonal.com"
    echo "   Senha: P10r1988!"
    echo ""
    echo "🔧 Comandos úteis:"
    echo "   Status: $0 status"
    echo "   Logs: $0 logs"
    echo "   Teste: $0 test"
    echo "   Reiniciar: $0 restart"
    echo ""
}

# Função para diagnóstico
diagnose() {
    log "🔍 Executando diagnóstico completo..."
    
    echo "📋 Informações do Sistema:"
    echo "   OS: $(lsb_release -d | cut -f2)"
    echo "   Kernel: $(uname -r)"
    echo "   Arquitetura: $(uname -m)"
    echo "   Uptime: $(uptime -p)"
    echo ""
    
    echo "💾 Informações de Memória:"
    free -h
    echo ""
    
    echo "💿 Informações de Disco:"
    df -h
    echo ""
    
    echo "🐳 Status do Docker:"
    if command -v docker &> /dev/null; then
        success "Docker está instalado"
        echo "   Versão: $(docker --version)"
        
        if sudo systemctl is-active --quiet docker; then
            success "Serviço Docker está rodando"
        else
            error "Serviço Docker não está rodando"
        fi
    else
        error "Docker não está instalado"
    fi
    echo ""
    
    echo "📦 Status do Docker Compose:"
    if command -v docker-compose &> /dev/null; then
        success "Docker Compose está instalado"
        echo "   Versão: $(docker-compose --version)"
    else
        error "Docker Compose não está instalado"
    fi
    echo ""
    
    echo "📊 Status dos Containers:"
    if [ -f "docker-compose.yml" ]; then
        sudo docker-compose ps
    else
        warning "Arquivo docker-compose.yml não encontrado"
    fi
    echo ""
    
    echo "🔌 Portas em uso:"
    sudo netstat -tlnp | grep -E ':(80|443|3000|3001|3306)' || echo "   Nenhuma das portas principais está em uso"
    echo ""
    
    echo "🏥 Testando Endpoints:"
    echo "   Backend Health Check:"
    if curl -f http://localhost:3001/health > /dev/null 2>&1; then
        success "   ✅ OK"
    else
        error "   ❌ FALHOU"
    fi
    
    echo "   Frontend:"
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        success "   ✅ OK"
    else
        error "   ❌ FALHOU"
    fi
    echo ""
    
    echo "🌐 Conectividade:"
    if ping -c 1 8.8.8.8 &> /dev/null; then
        success "   Internet: OK"
    else
        error "   Internet: FALHOU"
    fi
    
    if ping -c 1 personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com &> /dev/null; then
        success "   RDS: OK"
    else
        error "   RDS: FALHOU"
    fi
    echo ""
}

# Função para teste rápido
quick_test() {
    log "🧪 Executando teste rápido..."
    
    TESTS_PASSED=0
    TESTS_FAILED=0
    
    # Testar Docker
    if sudo systemctl is-active --quiet docker; then
        success "Docker: OK"
        ((TESTS_PASSED++))
    else
        error "Docker: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    # Testar containers
    if [ -f "docker-compose.yml" ] && sudo docker-compose ps | grep -q "Up"; then
        success "Containers: OK"
        ((TESTS_PASSED++))
    else
        error "Containers: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    # Testar endpoints
    if curl -f http://localhost:3001/health > /dev/null 2>&1; then
        success "Backend: OK"
        ((TESTS_PASSED++))
    else
        error "Backend: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        success "Frontend: OK"
        ((TESTS_PASSED++))
    else
        error "Frontend: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    echo ""
    echo "📊 Resultado: $TESTS_PASSED passaram, $TESTS_FAILED falharam"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        success "🎉 Todos os testes passaram!"
    else
        warning "⚠️ Alguns testes falharam. Execute '$0 diagnose' para mais detalhes."
    fi
}

# Função para mostrar logs
show_logs() {
    log "📋 Mostrando logs dos containers..."
    sudo docker-compose logs -f
}

# Função para mostrar status
show_status() {
    log "📊 Status dos containers:"
    sudo docker-compose ps
    echo ""
    log "📈 Uso de recursos:"
    sudo docker stats --no-stream
}

# Função para reiniciar
restart_containers() {
    log "🔄 Reiniciando containers..."
    sudo docker-compose restart
    success "Containers reiniciados"
}

# Função para parar
stop_containers() {
    log "🛑 Parando containers..."
    sudo docker-compose down
    success "Containers parados"
}

# Função para limpeza
cleanup() {
    log "🧹 Limpando containers e imagens antigas..."
    sudo docker-compose down
    sudo docker system prune -af
    sudo docker volume prune -f
    success "Limpeza concluída"
}

# Função para backup
backup_database() {
    log "💾 Fazendo backup do banco de dados..."
    
    BACKUP_DIR="/var/log/nh-personal/backups"
    DATE=$(date +%Y%m%d_%H%M%S)
    
    sudo mkdir -p $BACKUP_DIR
    
    if sudo docker-compose ps mysql | grep -q "Up"; then
        sudo docker-compose exec mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD:-password} personal_trainer_db > $BACKUP_DIR/db_backup_$DATE.sql
        success "Backup criado: $BACKUP_DIR/db_backup_$DATE.sql"
    else
        error "Container MySQL não está rodando"
    fi
}

# Função para clonar repositório
clone_repository() {
    log "📥 Clonando repositório..."
    
    if [ ! -d "projeto-personal" ]; then
        git clone https://github.com/nelsonholanda/personal.git projeto-personal
        if [ $? -ne 0 ]; then
            error "Falha ao clonar o repositório"
        fi
        success "Repositório clonado com sucesso"
    else
        success "Repositório já existe"
    fi
    
    cd projeto-personal
}

# Função principal
main() {
    # Verificar argumentos
    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi
    
    case "$1" in
        "deploy")
            check_ubuntu
            install_dependencies
            install_docker
            install_docker_compose
            configure_firewall
            setup_environment
            clone_repository
            deploy_application
            ;;
        "diagnose")
            diagnose
            ;;
        "test")
            quick_test
            ;;
        "logs")
            show_logs
            ;;
        "status")
            show_status
            ;;
        "restart")
            restart_containers
            ;;
        "stop")
            stop_containers
            ;;
        "cleanup")
            cleanup
            ;;
        "backup")
            backup_database
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Opção inválida: $1"
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@" 