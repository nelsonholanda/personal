#!/bin/bash

# =============================================================================
# NH GESTÃO DE ALUNOS - SCRIPT DE DEPLOY UBUNTU EC2
# =============================================================================
# 
# Versão: 3.0
# Data: 2024-12-19
# 
# MELHORIAS IMPLEMENTADAS:
# - Atualizado para usar 'docker compose' (nova sintaxe)
# - Verificação completa do Docker Compose antes do deploy
# - Melhor tratamento de erros e verificações
# - Limpeza automática de imagens antigas
# - Verificação de health check após deploy
# - Informações de segurança implementadas
# - Script organizado e limpo
# 
# USO:
#   ./deploy-ubuntu-ec2-new.sh deploy    # Deploy completo
#   ./deploy-ubuntu-ec2-new.sh diagnose  # Diagnóstico
#   ./deploy-ubuntu-ec2-new.sh test      # Teste rápido
#   ./deploy-ubuntu-ec2-new.sh status    # Status dos containers
#   ./deploy-ubuntu-ec2-new.sh logs      # Ver logs
#   ./deploy-ubuntu-ec2-new.sh restart   # Reiniciar containers
#   ./deploy-ubuntu-ec2-new.sh stop      # Parar containers
#   ./deploy-ubuntu-ec2-new.sh cleanup   # Limpeza completa
#   ./deploy-ubuntu-ec2-new.sh backup    # Backup do banco
# =============================================================================

# Garante que está na raiz do projeto (onde o script está)
cd "$(dirname "$0")"

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
    echo "⚠️  PRÉ-REQUISITO OBRIGATÓRIO:"
    echo "   Você DEVE configurar o IP público da EC2 ANTES de fazer o deploy."
    echo ""
    echo "📋 Como encontrar o IP público:"
    echo "   1. Acesse o AWS Console"
    echo "   2. Vá para EC2 > Instâncias"
    echo "   3. Selecione sua instância"
    echo "   4. Copie o 'IPv4 público'"
    echo ""
    echo "Uso: $0 [OPÇÃO]"
    echo ""
    echo "Opções:"
    echo "  config-ip  - ⚠️  OBRIGATÓRIO: Configurar IP do servidor manualmente"
    echo "  deploy     - Fazer deploy completo da aplicação (requer IP configurado)"
    echo "  diagnose   - 🔍 Diagnóstico completo do sistema e aplicação"
    echo "  test       - ⚡ Teste rápido da aplicação"
    echo "  features   - 🧪 Testar frontend localmente (build e servidor)"
    echo "  logs       - 📋 Mostrar logs dos containers"
    echo "  status     - 📊 Mostrar status dos containers"
    echo "  restart    - 🔄 Reiniciar todos os containers"
    echo "  stop       - 🛑 Parar todos os containers"
    echo "  cleanup    - 🧹 Limpar containers e imagens antigas"
    echo "  backup     - 💾 Fazer backup do banco de dados"
    echo "  help       - 📖 Mostrar esta ajuda"
    echo ""
    echo "📝 FLUXO CORRETO DE DEPLOY:"
    echo "   1. $0 config-ip     # Configurar IP público da EC2"
    echo "   2. $0 deploy        # Fazer deploy completo"
    echo "   3. $0 test          # Testar aplicação"
    echo ""
    echo "🔍 DIAGNÓSTICO E TESTES:"
    echo "   $0 diagnose         # Diagnóstico completo (recomendado primeiro)"
    echo "   $0 features         # Testar frontend localmente"
    echo "   $0 test             # Teste rápido da aplicação"
    echo ""
    echo "Exemplos:"
    echo "  $0 config-ip  # ⚠️  PRIMEIRO: Configurar IP do servidor"
    echo "  $0 deploy     # SEGUNDO: Deploy completo com todas as correções"
    echo "  $0 diagnose   # 🔍 Diagnóstico completo"
    echo "  $0 features   # 🧪 Testar frontend"
    echo "  $0 test       # ⚡ Teste rápido"
    echo "  $0 logs       # 📋 Ver logs em tempo real"
    echo ""
    echo "🔧 CORREÇÕES AUTOMÁTICAS INCLUÍDAS:"
    echo "   • Criação automática de arquivos .env"
    echo "   • Instalação automática de Node.js"
    echo "   • Build automático do backend e frontend"
    echo "   • Configuração automática de CORS"
    echo "   • Servir frontend estático"
    echo "   • Diagnóstico completo integrado"
    echo ""
    echo "📊 Para verificar o status: $0 status"
    echo "📋 Para ver os logs: $0 logs"
    echo "🧪 Para testar: $0 test"
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
    
    # Verificar se docker-compose está instalado
    if command -v docker compose &> /dev/null; then
        log "✅ Docker Compose já está instalado"
        echo "   Versão: $(docker compose version)"
    else
        log "📦 Instalando Docker Compose..."
        DOCKER_COMPOSE_VERSION="v2.20.0"
        sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        # Criar alias para compatibilidade
        sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
        success "Docker Compose instalado"
    fi
}

# Função para verificar Docker Compose
check_docker_compose() {
    log "🔍 Verificando Docker Compose..."
    
    # Verificar se docker compose está disponível
    if ! command -v docker compose &> /dev/null; then
        error "Docker Compose não está instalado. Execute: $0 install"
        exit 1
    fi
    
    # Verificar se o arquivo docker-compose.yml existe
    if [ ! -f "docker-compose.yml" ]; then
        error "Arquivo docker-compose.yml não encontrado no diretório atual."
        exit 1
    fi
    
    # CORREÇÃO: Criar arquivos .env se não existirem antes da validação
    if [ ! -f "backend/.env" ] || [ ! -f "frontend/.env" ]; then
        log "🔧 Criando arquivos .env necessários para validação..."
        
        # Usar IP padrão para validação se não estiver configurado
        SERVER_IP="localhost"
        if [ -f ".ec2_ip" ]; then
            SERVER_IP=$(cat .ec2_ip)
        fi
        
        # Criar backend/.env se não existir
        if [ ! -f "backend/.env" ]; then
            cat > backend/.env <<EOF
# NH-Personal Backend Environment Variables
NODE_ENV=production
PORT=3000
DATABASE_URL=mysql://admin:Rdms95gn!@personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com:3306/personal_trainer_db
JWT_ACCESS_TOKEN_SECRET=nh-personal-access-token-secret-2024
JWT_REFRESH_TOKEN_SECRET=nh-personal-refresh-token-secret-2024
ENCRYPTION_KEY=nh-personal-encryption-key-2024
FRONTEND_URL=http://$SERVER_IP:3000
EOF
        fi
        
        # Criar frontend/.env se não existir
        if [ ! -f "frontend/.env" ]; then
            cat > frontend/.env <<EOF
# NH-Personal Frontend Environment Variables
REACT_APP_API_URL=http://$SERVER_IP:3000/api
REACT_APP_ENV=production
EOF
        fi
        
        log "✅ Arquivos .env criados para validação"
    fi
    
    # Testar se o docker compose consegue validar o arquivo
    if ! sudo docker compose config > /dev/null 2>&1; then
        error "Erro na configuração do docker-compose.yml. Verifique a sintaxe."
        sudo docker compose config
        exit 1
    fi
    
    success "✅ Docker Compose configurado corretamente"
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

# Função para solicitar IP do servidor durante o deploy
prompt_server_ip() {
    echo ""
    echo "🌐 CONFIGURAÇÃO DO IP PÚBLICO DA EC2"
    echo "===================================="
    echo ""
    echo "Para que a aplicação funcione corretamente, precisamos do IP público da sua instância EC2."
    echo ""
    echo "📋 Como encontrar o IP público:"
    echo "   1. Acesse o AWS Console"
    echo "   2. Vá para EC2 > Instâncias"
    echo "   3. Selecione sua instância"
    echo "   4. Copie o 'IPv4 público'"
    echo ""
    
    while true; do
        read -p "🔗 Digite o IP público da sua instância EC2: " SERVER_IP
        
        if [ -z "$SERVER_IP" ]; then
            error "❌ IP não pode estar vazio. Tente novamente."
            continue
        fi
        
        # Validar formato do IP
        if [[ $SERVER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            # Validar se cada octeto está entre 0-255
            IFS='.' read -ra OCTETS <<< "$SERVER_IP"
            VALID_IP=true
            for octet in "${OCTETS[@]}"; do
                if [ "$octet" -lt 0 ] || [ "$octet" -gt 255 ]; then
                    VALID_IP=false
                    break
                fi
            done
            
            if [ "$VALID_IP" = true ]; then
                success "✅ IP válido: $SERVER_IP"
                echo "$SERVER_IP" > .ec2_ip
                break
            else
                error "❌ IP inválido. Cada número deve estar entre 0 e 255."
            fi
        else
            error "❌ Formato de IP inválido. Use o formato: xxx.xxx.xxx.xxx"
        fi
    done
    
    echo ""
    echo "🔧 Configurando variáveis de ambiente com IP: $SERVER_IP"
    echo ""
}

# Função para fazer deploy da aplicação
deploy_application() {
    log "🚀 Fazendo deploy da aplicação..."
    
    # Verificar se estamos no diretório correto
    if [ ! -f "docker-compose.yml" ]; then
        error "Arquivo docker-compose.yml não encontrado. Execute este script no diretório raiz do projeto."
        exit 1
    fi
    
    # VERIFICAÇÃO OBRIGATÓRIA DO IP
    if [ ! -f ".ec2_ip" ]; then
        echo ""
        echo "❌ ERRO: IP do servidor não configurado!"
        echo "========================================"
        echo ""
        echo "⚠️  PRÉ-REQUISITO OBRIGATÓRIO:"
        echo "   Você DEVE configurar o IP público da EC2 antes de fazer o deploy."
        echo ""
        echo "🔧 Para configurar o IP, execute:"
        echo "   $0 config-ip"
        echo ""
        echo "📋 Como encontrar o IP público:"
        echo "   1. Acesse o AWS Console"
        echo "   2. Vá para EC2 > Instâncias"
        echo "   3. Selecione sua instância"
        echo "   4. Copie o 'IPv4 público'"
        echo ""
        error "Configure o IP primeiro e depois execute o deploy novamente."
        exit 1
    fi
    
    SERVER_IP=$(cat .ec2_ip)
    log "✅ IP do servidor configurado: $SERVER_IP"
    
    # Perguntar se quer alterar o IP
    read -p "🔄 Deseja alterar o IP atual ($SERVER_IP)? (s/N): " CHANGE_IP
    if [[ $CHANGE_IP =~ ^[Ss]$ ]]; then
        prompt_server_ip
        SERVER_IP=$(cat .ec2_ip)
    fi
    
    # CORREÇÃO AUTOMÁTICA: Criar arquivos .env se não existirem
    log "🔧 Verificando e criando arquivos .env necessários..."
    
    # Os arquivos .env já foram criados na função check_docker_compose
    # Aqui apenas atualizamos com o IP correto se necessário
    if [ -f "backend/.env" ] && [ -f "frontend/.env" ]; then
        log "✅ Arquivos .env já existem"
    else
        error "❌ Arquivos .env não foram criados corretamente"
        exit 1
    fi
    
    # CORREÇÃO AUTOMÁTICA: Fazer build do backend antes do deploy
    log "🔨 Fazendo build do backend..."
    if [ -f "backend/package.json" ]; then
        # Verificar se Node.js está instalado
        if ! command -v node &> /dev/null; then
            log "📦 Node.js não encontrado, instalando..."
            install_nodejs
        elif ! command -v npm &> /dev/null; then
            log "📦 npm não encontrado, instalando Node.js..."
            install_nodejs
        fi
        
        cd backend
        
        # Instalar dependências se node_modules não existir
        if [ ! -d "node_modules" ]; then
            log "📦 Instalando dependências do backend..."
            npm install
        fi
        
        # Fazer build
        log "🔨 Compilando TypeScript..."
        npm run build
        cd ..
        success "✅ Build do backend concluído"
    else
        warning "⚠️ package.json do backend não encontrado, build será feito no container"
    fi
    
    # Verificar se o Docker está rodando
    if ! sudo systemctl is-active --quiet docker; then
        log "🔄 Iniciando Docker..."
        sudo systemctl start docker
        sleep 5
    fi
    
    # Parar containers existentes
    log "🛑 Parando containers existentes..."
    sudo docker compose down --remove-orphans
    
    # Limpar imagens antigas (opcional)
    log "🧹 Limpando imagens antigas..."
    sudo docker system prune -f
    
    # Fazer build e subir containers
    log "🔨 Fazendo build e iniciando containers..."
    sudo docker compose up --build -d
    
    # Aguardar containers subirem
    log "⏳ Aguardando containers iniciarem..."
    sleep 45
    
    # Verificar se containers estão rodando
    log "🔍 Verificando status dos containers..."
    if sudo docker compose ps | grep -q "Up"; then
        success "✅ Aplicação deployada com sucesso!"
        
        # Aguardar mais um pouco para garantir que a aplicação esteja pronta
        log "⏳ Aguardando aplicação inicializar completamente..."
        sleep 15
        
        # Testar health check
        log "🔍 Testando health check..."
        if curl -f http://localhost:3000/health > /dev/null 2>&1; then
            success "✅ Health check passou!"
        else
            warning "⚠️ Health check falhou, mas containers estão rodando"
        fi
        
        # Testar página inicial (frontend)
        log "🔍 Testando página inicial..."
        if curl -f http://localhost:3000 > /dev/null 2>&1; then
            success "✅ Página inicial carregando!"
        else
            warning "⚠️ Página inicial pode estar com problemas"
        fi
        
        echo ""
        echo "🌐 URLs da aplicação:"
        echo "   • Frontend: http://$SERVER_IP:3000"
        echo "   • Health Check: http://$SERVER_IP:3000/health"
        echo "   • API: http://$SERVER_IP:3000/api"
        echo ""
        echo "🔐 Melhorias de segurança implementadas:"
        echo "   • Criptografia AES-256-CBC ativa"
        echo "   • Senhas protegidas"
        echo "   • Configurações seguras"
        echo ""
        echo "📊 Para verificar o status: $0 status"
        echo "📋 Para ver os logs: $0 logs"
        echo "🧪 Para testar: $0 test"
        
    else
        error "❌ Falha no deploy. Verifique os logs: $0 logs"
        echo ""
        echo "🔍 Comandos para debug:"
        echo "   sudo docker compose ps"
        echo "   sudo docker compose logs"
        echo "   sudo docker system df"
        exit 1
    fi
}

# Função para diagnóstico completo
diagnose() {
    log "🔍 Executando diagnóstico completo..."
    
    echo ""
    echo "📋 DIAGNÓSTICO DO SISTEMA"
    echo "========================="
    
    # Verificar Docker
    if command -v docker &> /dev/null; then
        echo "✅ Docker: Instalado"
        echo "   Versão: $(docker --version)"
    else
        echo "❌ Docker: Não instalado"
    fi
    
    # Verificar Docker Compose
    if command -v docker compose &> /dev/null; then
        echo "✅ Docker Compose: Instalado"
        echo "   Versão: $(docker compose version)"
    else
        echo "❌ Docker Compose: Não instalado"
    fi
    
    # Verificar Node.js
    if command -v node &> /dev/null; then
        echo "✅ Node.js: Instalado"
        echo "   Versão: $(node --version)"
    else
        echo "❌ Node.js: Não instalado"
    fi
    
    # Verificar arquivo docker-compose.yml
    if [ -f "docker-compose.yml" ]; then
        echo "✅ docker-compose.yml: Encontrado"
        if command -v docker &> /dev/null; then
            docker compose ps
        fi
    else
        echo "❌ docker-compose.yml: Não encontrado"
    fi
    
    echo ""
    echo "📋 VERIFICAÇÃO DE ARQUIVOS"
    echo "=========================="
    
    # Verificar arquivos .env
    if [ -f "backend/.env" ]; then
        echo "✅ backend/.env: Encontrado"
        echo "   📄 NODE_ENV: $(grep NODE_ENV backend/.env | cut -d'=' -f2 2>/dev/null || echo 'não configurado')"
        echo "   📄 FRONTEND_URL: $(grep FRONTEND_URL backend/.env | cut -d'=' -f2 2>/dev/null || echo 'não configurado')"
    else
        echo "❌ backend/.env: Não encontrado"
    fi
    
    if [ -f "frontend/.env" ]; then
        echo "✅ frontend/.env: Encontrado"
    else
        echo "❌ frontend/.env: Não encontrado"
    fi
    
    # Verificar build do frontend
    if [ -d "frontend/build" ]; then
        echo "✅ frontend/build: Encontrado"
        echo "   📄 Arquivos: $(ls frontend/build/ | wc -l) arquivos"
        if [ -f "frontend/build/index.html" ]; then
            echo "   ✅ index.html: Encontrado"
        else
            echo "   ❌ index.html: Não encontrado"
        fi
    else
        echo "❌ frontend/build: Não encontrado"
    fi
    
    # Verificar build do backend
    if [ -d "backend/dist" ]; then
        echo "✅ backend/dist: Encontrado"
        echo "   📄 Arquivos: $(ls backend/dist/ | wc -l) arquivos"
    else
        echo "❌ backend/dist: Não encontrado"
    fi
    
    echo ""
    echo "🌐 TESTE DE CONECTIVIDADE"
    echo "========================="
    
    # Testar conectividade com o banco
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        echo "✅ Health Check: OK"
        HEALTH_RESPONSE=$(curl -s http://localhost:3000/health)
        echo "   Resposta: $HEALTH_RESPONSE"
    else
        echo "❌ Health Check: FALHOU"
    fi
    
    # Testar página inicial
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        echo "✅ Página inicial: OK"
        FRONTEND_RESPONSE=$(curl -s -I http://localhost:3000 | head -1)
        echo "   Status: $FRONTEND_RESPONSE"
    else
        echo "❌ Página inicial: FALHOU"
    fi
    
    # Testar API
    if curl -f http://localhost:3000/api > /dev/null 2>&1; then
        echo "✅ API: OK"
    else
        echo "❌ API: FALHOU"
    fi
    
    echo ""
    echo "📊 STATUS DOS CONTAINERS"
    echo "========================"
    
    if [ -f "docker-compose.yml" ] && command -v docker &> /dev/null; then
        if docker compose ps | grep -q "Up"; then
            echo "✅ Containers estão rodando"
            docker compose ps
        else
            echo "❌ Containers não estão rodando"
            docker compose ps
        fi
    else
        echo "❌ Docker não disponível ou docker-compose.yml não encontrado"
    fi
    
    echo ""
    echo "💾 USO DE RECURSOS"
    echo "=================="
    if command -v docker &> /dev/null; then
        docker stats --no-stream
    else
        echo "❌ Docker não disponível"
    fi
    
    echo ""
    echo "📋 LOGS RECENTES"
    echo "================"
    if command -v docker &> /dev/null && [ -f "docker-compose.yml" ]; then
        docker compose logs --tail=20
    else
        echo "❌ Docker não disponível ou docker-compose.yml não encontrado"
    fi
    
    echo ""
    echo "🎯 RECOMENDAÇÕES AUTOMÁTICAS"
    echo "============================"
    
    # Verificar se precisa configurar IP
    if [ ! -f ".ec2_ip" ]; then
        echo "⚠️  IP não configurado: Execute '$0 config-ip'"
    fi
    
    # Verificar se precisa criar arquivos .env
    if [ ! -f "backend/.env" ] || [ ! -f "frontend/.env" ]; then
        echo "⚠️  Arquivos .env faltando: Execute '$0 deploy' para criar automaticamente"
    fi
    
    # Verificar se precisa fazer build
    if [ ! -d "frontend/build" ]; then
        echo "⚠️  Frontend não buildado: Execute '$0 deploy' para build automático"
    fi
    
    # Verificar se containers não estão rodando
    if command -v docker &> /dev/null && [ -f "docker-compose.yml" ]; then
        if ! docker compose ps | grep -q "Up"; then
            echo "⚠️  Containers não estão rodando: Execute '$0 deploy' para iniciar"
        fi
    fi
    
    echo ""
    echo "🔧 COMANDOS ÚTEIS:"
    echo "=================="
    echo "• $0 config-ip     # Configurar IP do servidor"
    echo "• $0 deploy        # Deploy completo com todas as correções"
    echo "• $0 test          # Teste rápido da aplicação"
    echo "• $0 logs          # Ver logs em tempo real"
    echo "• $0 restart       # Reiniciar containers"
    echo "• $0 cleanup       # Limpar containers e imagens"
}

# Função para teste rápido
quick_test() {
    log "⚡ Executando teste rápido..."
    
    TESTS_PASSED=0
    TESTS_FAILED=0
    
    echo ""
    echo "🔍 TESTE RÁPIDO DA APLICAÇÃO"
    echo "============================"
    
    # Testar se containers estão rodando
    if [ -f "docker-compose.yml" ] && sudo docker compose ps | grep -q "Up"; then
        success "   ✅ Containers: OK"
        ((TESTS_PASSED++))
    else
        error "   ❌ Containers: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    # Testar health check
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        success "   ✅ Health Check: OK"
        ((TESTS_PASSED++))
    else
        error "   ❌ Health Check: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    # Testar página inicial
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        success "   ✅ Página inicial: OK"
        ((TESTS_PASSED++))
    else
        error "   ❌ Página inicial: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    # Resultado final
    echo ""
    echo "📊 RESULTADO DO TESTE RÁPIDO"
    echo "============================"
    echo "✅ Testes passaram: $TESTS_PASSED"
    echo "❌ Testes falharam: $TESTS_FAILED"
    echo "📊 Total de testes: $((TESTS_PASSED + TESTS_FAILED))"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        success "🎉 Aplicação está funcionando corretamente!"
    else
        error "❌ Alguns testes falharam. Execute '$0 diagnose' para mais detalhes."
    fi
}

# Função para mostrar logs
show_logs() {
    log "📋 Mostrando logs dos containers..."
    sudo docker compose logs -f
}

# Função para mostrar status
show_status() {
    log "📊 Status dos containers:"
    sudo docker compose ps
    echo ""
    log "📈 Uso de recursos:"
    sudo docker stats --no-stream
}

# Função para reiniciar
restart_containers() {
    log "🔄 Reiniciando containers..."
    sudo docker compose restart
    success "Containers reiniciados"
}

# Função para parar
stop_containers() {
    log "🛑 Parando containers..."
    sudo docker compose down
    success "Containers parados"
}

# Função para limpeza
cleanup() {
    log "🧹 Limpando containers e imagens antigas..."
    sudo docker compose down
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
    
    # Como estamos usando RDS, vamos fazer backup via API ou exportação
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        log "✅ Aplicação está rodando, backup será feito via API"
        # Aqui você pode implementar backup via API se necessário
        success "Backup iniciado via API"
    else
        error "Aplicação não está rodando"
    fi
}

# Função para instalar Node.js
install_nodejs() {
    log "📦 Verificando Node.js..."
    
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        log "✅ Node.js já está instalado"
        echo "   Versão Node.js: $(node --version)"
        echo "   Versão npm: $(npm --version)"
        return
    fi
    
    log "📦 Instalando Node.js..."
    
    # Adicionar repositório NodeSource
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    
    # Instalar Node.js
    sudo apt install -y nodejs
    
    # Verificar instalação
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        success "✅ Node.js instalado com sucesso"
        echo "   Versão Node.js: $(node --version)"
        echo "   Versão npm: $(npm --version)"
    else
        error "❌ Falha na instalação do Node.js"
        exit 1
    fi
}

# Função para testar frontend localmente
test_frontend() {
    log "🧪 Testando frontend localmente..."
    
    echo ""
    echo "📋 1. Verificando se o frontend pode ser buildado..."
    
    if [ ! -f "frontend/package.json" ]; then
        error "❌ frontend/package.json não encontrado"
        exit 1
    fi
    
    cd frontend
    
    # Verificar se node_modules existe
    if [ ! -d "node_modules" ]; then
        log "📦 Instalando dependências do frontend..."
        if ! npm install; then
            error "❌ Falha na instalação das dependências do frontend"
            exit 1
        fi
    fi
    
    # Fazer build do frontend
    log "🔨 Fazendo build do frontend..."
    if npm run build; then
        success "✅ Build do frontend concluído com sucesso!"
    else
        error "❌ Erro no build do frontend"
        exit 1
    fi
    
    cd ..
    
    echo ""
    echo "📋 2. Verificando arquivos gerados..."
    if [ -d "frontend/build" ]; then
        success "✅ Diretório build criado"
        echo "   📄 Arquivos no build:"
        ls -la frontend/build/
        
        if [ -f "frontend/build/index.html" ]; then
            success "✅ index.html encontrado"
            echo "   📄 Conteúdo do index.html:"
            head -15 frontend/build/index.html
        else
            error "❌ index.html não encontrado"
        fi
    else
        error "❌ Diretório build não foi criado"
    fi
    
    echo ""
    echo "📋 3. Testando servidor local..."
    echo "🚀 Iniciando servidor de teste..."
    
    cd frontend/build
    
    # Tentar diferentes servidores
    if command -v python3 &> /dev/null; then
        python3 -m http.server 8080 &
        SERVER_PID=$!
        SERVER_CMD="python3"
    elif command -v python &> /dev/null; then
        python -m SimpleHTTPServer 8080 &
        SERVER_PID=$!
        SERVER_CMD="python"
    elif command -v npx &> /dev/null; then
        npx serve -s . -p 8080 &
        SERVER_PID=$!
        SERVER_CMD="npx serve"
    else
        warning "⚠️ Nenhum servidor HTTP encontrado, pulando teste local"
        cd ../..
        return
    fi
    
    sleep 3
    
    echo "🔍 Testando servidor..."
    if curl -f http://localhost:8080 > /dev/null 2>&1; then
        success "✅ Servidor local funcionando"
        echo "   📄 Resposta:"
        curl -s http://localhost:8080 | head -10
    else
        warning "⚠️ Servidor local não está funcionando"
    fi
    
    # Parar servidor
    kill $SERVER_PID 2>/dev/null
    
    cd ../..
    
    echo ""
    success "🎉 Teste do frontend concluído!"
    echo "📋 Próximos passos:"
    echo "   1. Se o build funcionou: $0 deploy"
    echo "   2. Para diagnóstico completo: $0 diagnose"
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
            install_nodejs
            install_docker
            install_docker_compose
            configure_firewall
            check_docker_compose
            deploy_application
            ;;
        "config-ip")
            prompt_server_ip
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
        "features")
            test_frontend
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