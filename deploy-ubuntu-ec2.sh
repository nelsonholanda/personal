#!/bin/bash

# Script Completo de Deploy para Ubuntu EC2 - NH Gestão de Alunos
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
    echo "🚀 Script de Deploy para Ubuntu EC2 - NH Gestão de Alunos"
    echo "========================================================"
    echo ""
    echo "Uso: $0 [OPÇÃO]"
    echo ""
    echo "Opções:"
    echo "  deploy     - Fazer deploy completo da aplicação"
    echo "  diagnose   - Executar diagnóstico completo"
    echo "  test       - Executar teste rápido"
    echo "  features   - Testar funcionalidades da aplicação"
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
    echo "  $0 features   # Testar funcionalidades da aplicação"
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
RDS_HOSTNAME=personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com
RDS_PORT=3306
RDS_USERNAME=admin
RDS_PASSWORD=$DB_PASSWORD
RDS_DATABASE=personal_trainer_db
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
    echo "⚠️  IMPORTANTE: Configure as credenciais de administrador após o deploy!"
    echo "   Execute: sudo docker-compose exec backend node scripts/create-admin-user.js"
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

# Função para testar funcionalidades da aplicação
test_application_features() {
    log "🧪 Testando funcionalidades da aplicação..."
    
    # Aguardar um pouco mais para garantir que tudo está funcionando
    sleep 10
    
    TESTS_PASSED=0
    TESTS_FAILED=0
    
    echo "🔍 Testando funcionalidades principais..."
    
    # 1. Testar página inicial (Home)
    log "📄 Testando página inicial..."
    HOME_RESPONSE=$(curl -s -f http://localhost:3000 2>/dev/null || echo "FAILED")
    if echo "$HOME_RESPONSE" | grep -q "html\|React\|NH Gestão"; then
        success "   ✅ Página inicial: OK"
        ((TESTS_PASSED++))
    else
        error "   ❌ Página inicial: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    # 2. Testar login de administrador
    log "🔐 Testando login de administrador..."
    LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3001/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"nholanda@nhpersonal.com","password":"P10r1988!"}' 2>/dev/null || echo "FAILED")
    
    if echo "$LOGIN_RESPONSE" | grep -q "token\|access_token"; then
        success "   ✅ Login administrador: OK"
        # Extrair token para testes subsequentes
        TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
        ((TESTS_PASSED++))
    else
        error "   ❌ Login administrador: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    # 3. Testar gestão de clientes (se token foi obtido)
    if [ ! -z "$TOKEN" ]; then
        log "👥 Testando gestão de clientes..."
        
        # Testar listagem de clientes
        CLIENTS_RESPONSE=$(curl -s -f http://localhost:3001/api/clients \
            -H "Authorization: Bearer $TOKEN" 2>/dev/null || echo "FAILED")
        
        if echo "$CLIENTS_RESPONSE" | grep -q "clients\|data\|[]"; then
            success "   ✅ Listagem de clientes: OK"
            ((TESTS_PASSED++))
        else
            error "   ❌ Listagem de clientes: FALHOU"
            ((TESTS_FAILED++))
        fi
        
        # Testar criação de cliente
        CREATE_CLIENT_RESPONSE=$(curl -s -X POST http://localhost:3001/api/clients \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d '{"name":"Cliente Teste","email":"teste@teste.com","phone":"11999999999"}' 2>/dev/null || echo "FAILED")
        
        if echo "$CREATE_CLIENT_RESPONSE" | grep -q "id\|name\|Cliente Teste"; then
            success "   ✅ Criação de cliente: OK"
            ((TESTS_PASSED++))
        else
            error "   ❌ Criação de cliente: FALHOU"
            ((TESTS_FAILED++))
        fi
    else
        warning "   ⚠️ Testes de clientes: Token não disponível"
        ((TESTS_FAILED++))
    fi
    
    # 4. Testar gestão de pagamentos
    if [ ! -z "$TOKEN" ]; then
        log "💰 Testando gestão de pagamentos..."
        
        # Testar listagem de pagamentos
        PAYMENTS_RESPONSE=$(curl -s -f http://localhost:3001/api/payments \
            -H "Authorization: Bearer $TOKEN" 2>/dev/null || echo "FAILED")
        
        if echo "$PAYMENTS_RESPONSE" | grep -q "payments\|data\|[]"; then
            success "   ✅ Listagem de pagamentos: OK"
            ((TESTS_PASSED++))
        else
            error "   ❌ Listagem de pagamentos: FALHOU"
            ((TESTS_FAILED++))
        fi
        
        # Testar criação de pagamento
        CREATE_PAYMENT_RESPONSE=$(curl -s -X POST http://localhost:3001/api/payments \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d '{"clientId":1,"amount":100.00,"dueDate":"2024-12-31","status":"pending"}' 2>/dev/null || echo "FAILED")
        
        if echo "$CREATE_PAYMENT_RESPONSE" | grep -q "id\|amount\|100.00"; then
            success "   ✅ Criação de pagamento: OK"
            ((TESTS_PASSED++))
        else
            error "   ❌ Criação de pagamento: FALHOU"
            ((TESTS_FAILED++))
        fi
    else
        warning "   ⚠️ Testes de pagamentos: Token não disponível"
        ((TESTS_FAILED++))
    fi
    
    # 5. Testar frequência de clientes
    if [ ! -z "$TOKEN" ]; then
        log "📊 Testando frequência de clientes..."
        
        # Testar listagem de frequência
        FREQUENCY_RESPONSE=$(curl -s -f http://localhost:3001/api/clients/frequency \
            -H "Authorization: Bearer $TOKEN" 2>/dev/null || echo "FAILED")
        
        if echo "$FREQUENCY_RESPONSE" | grep -q "frequency\|data\|[]"; then
            success "   ✅ Listagem de frequência: OK"
            ((TESTS_PASSED++))
        else
            error "   ❌ Listagem de frequência: FALHOU"
            ((TESTS_FAILED++))
        fi
    else
        warning "   ⚠️ Testes de frequência: Token não disponível"
        ((TESTS_FAILED++))
    fi
    
    # 6. Testar relatórios por período
    if [ ! -z "$TOKEN" ]; then
        log "📈 Testando relatórios por período..."
        
        # Testar relatório de pagamentos por período
        REPORT_RESPONSE=$(curl -s -f "http://localhost:3001/api/payments/report?startDate=2024-01-01&endDate=2024-12-31" \
            -H "Authorization: Bearer $TOKEN" 2>/dev/null || echo "FAILED")
        
        if echo "$REPORT_RESPONSE" | grep -q "report\|data\|received\|pending"; then
            success "   ✅ Relatório de pagamentos: OK"
            ((TESTS_PASSED++))
        else
            error "   ❌ Relatório de pagamentos: FALHOU"
            ((TESTS_FAILED++))
        fi
        
        # Testar relatório financeiro
        FINANCIAL_REPORT_RESPONSE=$(curl -s -f "http://localhost:3001/api/payments/financial-report?startDate=2024-01-01&endDate=2024-12-31" \
            -H "Authorization: Bearer $TOKEN" 2>/dev/null || echo "FAILED")
        
        if echo "$FINANCIAL_REPORT_RESPONSE" | grep -q "financial\|received\|pending\|total"; then
            success "   ✅ Relatório financeiro: OK"
            ((TESTS_PASSED++))
        else
            error "   ❌ Relatório financeiro: FALHOU"
            ((TESTS_FAILED++))
        fi
    else
        warning "   ⚠️ Testes de relatórios: Token não disponível"
        ((TESTS_FAILED++))
    fi
    
    # 7. Testar dashboard
    if [ ! -z "$TOKEN" ]; then
        log "📊 Testando dashboard..."
        
        DASHBOARD_RESPONSE=$(curl -s -f http://localhost:3001/api/dashboard \
            -H "Authorization: Bearer $TOKEN" 2>/dev/null || echo "FAILED")
        
        if echo "$DASHBOARD_RESPONSE" | grep -q "dashboard\|stats\|summary"; then
            success "   ✅ Dashboard: OK"
            ((TESTS_PASSED++))
        else
            error "   ❌ Dashboard: FALHOU"
            ((TESTS_FAILED++))
        fi
    else
        warning "   ⚠️ Testes de dashboard: Token não disponível"
        ((TESTS_FAILED++))
    fi
    
    # 8. Testar páginas do frontend
    log "🌐 Testando páginas do frontend..."
    
    # Testar página de login
    LOGIN_PAGE_RESPONSE=$(curl -s -f http://localhost:3000/login 2>/dev/null || echo "FAILED")
    if echo "$LOGIN_PAGE_RESPONSE" | grep -q "html\|login\|form"; then
        success "   ✅ Página de login: OK"
        ((TESTS_PASSED++))
    else
        error "   ❌ Página de login: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    # Testar página de clientes
    CLIENTS_PAGE_RESPONSE=$(curl -s -f http://localhost:3000/clients 2>/dev/null || echo "FAILED")
    if echo "$CLIENTS_PAGE_RESPONSE" | grep -q "html\|clients\|management"; then
        success "   ✅ Página de clientes: OK"
        ((TESTS_PASSED++))
    else
        error "   ❌ Página de clientes: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    # Testar página de pagamentos
    PAYMENTS_PAGE_RESPONSE=$(curl -s -f http://localhost:3000/payments 2>/dev/null || echo "FAILED")
    if echo "$PAYMENTS_PAGE_RESPONSE" | grep -q "html\|payments\|financial"; then
        success "   ✅ Página de pagamentos: OK"
        ((TESTS_PASSED++))
    else
        error "   ❌ Página de pagamentos: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    # Testar página de relatórios
    REPORTS_PAGE_RESPONSE=$(curl -s -f http://localhost:3000/reports 2>/dev/null || echo "FAILED")
    if echo "$REPORTS_PAGE_RESPONSE" | grep -q "html\|reports\|analytics"; then
        success "   ✅ Página de relatórios: OK"
        ((TESTS_PASSED++))
    else
        error "   ❌ Página de relatórios: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    # Resultado final dos testes
    echo ""
    echo "📊 RESULTADO DOS TESTES DE FUNCIONALIDADES"
    echo "=========================================="
    echo "✅ Testes passaram: $TESTS_PASSED"
    echo "❌ Testes falharam: $TESTS_FAILED"
    echo "📊 Total de testes: $((TESTS_PASSED + TESTS_FAILED))"
    
    if [ $((TESTS_PASSED + TESTS_FAILED)) -gt 0 ]; then
        SUCCESS_RATE=$((TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED)))
        echo "📈 Taxa de sucesso: ${SUCCESS_RATE}%"
    fi
    
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        success "🎉 Todas as funcionalidades estão funcionando corretamente!"
        echo ""
        echo "✅ Funcionalidades testadas e funcionando:"
        echo "   • Página inicial (Home)"
        echo "   • Login de administrador"
        echo "   • Gestão de clientes (listar e criar)"
        echo "   • Gestão de pagamentos (listar e criar)"
        echo "   • Frequência de clientes"
        echo "   • Relatórios por período"
        echo "   • Relatórios financeiros (recebidos e a receber)"
        echo "   • Dashboard"
        echo "   • Páginas do frontend (login, clientes, pagamentos, relatórios)"
    elif [ $TESTS_FAILED -lt 5 ]; then
        warning "⚠️ A maioria das funcionalidades está funcionando, mas alguns problemas foram encontrados."
        echo "   Execute '$0 diagnose' para mais detalhes."
    else
        error "❌ Muitas funcionalidades falharam. Verifique os logs e configurações."
        echo "   Execute '$0 logs' para ver os logs detalhados."
    fi
    
    echo ""
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
            test_application_features
            ;;
        "diagnose")
            diagnose
            ;;
        "test")
            quick_test
            ;;
        "features")
            test_application_features
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

# --- [NH GESTÃO DE ALUNOS] GARANTIR DEPENDÊNCIAS DO FRONTEND ---
log "🧹 Limpando dependências antigas do frontend..."
cd frontend
rm -rf node_modules package-lock.json

log "🔍 Garantindo que react-scripts está no package.json..."
if ! grep -q '"react-scripts"' package.json; then
  npm install react-scripts@5.0.1 --save
fi

log "📦 Instalando dependências do frontend..."
npm install
cd ..

# --- [NH GESTÃO DE ALUNOS] BUILD DOCKER SEM CACHE PARA FRONTEND ---
log "🐳 Buildando imagem Docker do frontend sem cache..."
docker compose build --no-cache frontend

# Executar função principal
main "$@" 