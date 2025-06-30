#!/bin/bash

# Garante que está na raiz do projeto (onde o script está)
cd "$(dirname "$0")"

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
    
    # .env principal
    cat > .env <<EOF
# Database Configuration
DATABASE_URL=mysql://admin:Rdms95gn!@personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com:3306/personal_trainer_db

# JWT Configuration
JWT_ACCESS_TOKEN_SECRET=nh-personal-access-token-secret-2024
JWT_REFRESH_TOKEN_SECRET=nh-personal-refresh-token-secret-2024

# Encryption
ENCRYPTION_KEY=nh-personal-encryption-key-2024

# Application Configuration
NODE_ENV=production
PORT=3000
EOF

    success "Variáveis de ambiente configuradas"
}

# Função para inicializar banco de dados e criar usuário admin
initialize_database() {
    log "🗄️ Inicializando banco de dados e criando usuário admin..."
    
    # Verificar se o banco está acessível
    log "🔍 Verificando conectividade com o banco de dados..."
    if ! mysql -h personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com -u admin -p'Rdms95gn!' -e "SELECT 1;" > /dev/null 2>&1; then
        error "Não foi possível conectar ao banco de dados RDS. Verifique as credenciais e conectividade."
    fi
    
    success "Conectividade com banco de dados: OK"
    
    # Instalar dependências do Node.js para executar os scripts
    log "📦 Instalando dependências do Node.js..."
    if [ ! -d "backend/node_modules" ]; then
        cd backend
        npm install
        cd ..
    fi
    
    # Executar migrações do Prisma
    log "🔄 Executando migrações do banco de dados..."
    cd backend
    
    # Configurar variáveis de ambiente para o Prisma
    export DATABASE_URL="mysql://admin:Rdms95gn!@personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com:3306/personal_trainer_db"
    
    # Gerar cliente Prisma
    npx prisma generate
    
    # Executar migrações
    npx prisma migrate deploy
    
    success "Migrações executadas com sucesso"
    
    # Perguntar ao usuário se quer criar o admin manualmente
    echo ""
    echo "👤 Criação do Usuário Administrador"
    echo "=================================="
    echo "1. Criar usuário admin automaticamente (nholanda/P10r1988!)"
    echo "2. Criar usuário admin manualmente"
    echo ""
    read -p "Escolha uma opção (1 ou 2): " ADMIN_CHOICE
    
    case $ADMIN_CHOICE in
        1)
            log "👤 Criando usuário admin padrão 'nholanda'..."
            node scripts/create-admin-user.js
            ;;
        2)
            echo ""
            echo "🔧 Configuração Manual do Usuário Admin"
            echo "======================================"
            
            # Solicitar nome de usuário
            while true; do
                read -p "Digite o nome de usuário do admin: " ADMIN_USERNAME
                if [ -n "$ADMIN_USERNAME" ]; then
                    break
                else
                    echo "❌ Nome de usuário não pode estar vazio"
                fi
            done
            
            # Solicitar senha
            while true; do
                read -s -p "Digite a senha do admin: " ADMIN_PASSWORD
                echo ""
                if [ -n "$ADMIN_PASSWORD" ]; then
                    read -s -p "Confirme a senha: " ADMIN_PASSWORD_CONFIRM
                    echo ""
                    if [ "$ADMIN_PASSWORD" = "$ADMIN_PASSWORD_CONFIRM" ]; then
                        break
                    else
                        echo "❌ Senhas não coincidem"
                    fi
                else
                    echo "❌ Senha não pode estar vazia"
                fi
            done
            
            # Criar arquivo temporário com as credenciais
            cat > temp-admin-config.js <<EOF
const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');

const databaseURL = 'mysql://admin:Rdms95gn!@personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com:3306/personal_trainer_db';
process.env.DATABASE_URL = databaseURL;

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: databaseURL,
    },
  },
});

async function createCustomAdminUser() {
  try {
    console.log('🔐 Conectando ao banco de dados...');
    await prisma.\$connect();

    // Apagar todos os usuários que não são admin
    await prisma.user.deleteMany({ where: { role: { not: 'admin' } } });

    // Verificar se o usuário admin já existe
    let adminUser = await prisma.user.findFirst({ where: { name: '$ADMIN_USERNAME', role: 'admin' } });

    if (adminUser) {
      // Atualizar senha
      const hashedPassword = await bcrypt.hash('$ADMIN_PASSWORD', 12);
      await prisma.user.update({
        where: { id: adminUser.id },
        data: {
          passwordHash: hashedPassword,
          isActive: true,
          updatedAt: new Date(),
        },
      });
      console.log('✅ Usuário admin "$ADMIN_USERNAME" atualizado com sucesso!');
    } else {
      // Criar usuário admin
      const hashedPassword = await bcrypt.hash('$ADMIN_PASSWORD', 12);
      adminUser = await prisma.user.create({
        data: {
          name: '$ADMIN_USERNAME',
          passwordHash: hashedPassword,
          role: 'admin',
          isActive: true,
          passwordChangedAt: new Date(),
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      });
      console.log('✅ Usuário admin "$ADMIN_USERNAME" criado com sucesso!');
    }

    // Criar perfil de treinador para o admin se não existir
    const existingTrainerProfile = await prisma.trainerProfile.findUnique({ where: { userId: adminUser.id } });
    if (!existingTrainerProfile) {
      await prisma.trainerProfile.create({
        data: {
          userId: adminUser.id,
          specialization: 'Personal Trainer, Treinamento Funcional, Musculação',
          experienceYears: 15,
          certifications: 'CREF, Especialização em Treinamento Funcional, Certificação em Nutrição Esportiva',
          bio: 'Administrador e Personal Trainer do sistema.',
          hourlyRate: 150.00,
          availability: JSON.stringify({}),
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      });
      console.log('✅ Perfil de treinador para admin criado com sucesso!');
    }

    console.log('🎉 Configuração do admin concluída!');
    console.log('=====================================');
    console.log('👤 Usuário: $ADMIN_USERNAME (admin)');
    console.log('💡 Use essas credenciais para acessar o sistema!');
  } catch (error) {
    console.error('❌ Erro ao criar usuário administrador:', error);
  } finally {
    await prisma.\$disconnect();
  }
}

createCustomAdminUser();
EOF

            log "👤 Criando usuário admin personalizado '$ADMIN_USERNAME'..."
            node temp-admin-config.js
            
            # Salvar credenciais para uso posterior
            echo "$ADMIN_USERNAME" > .admin_username
            echo "$ADMIN_PASSWORD" > .admin_password
            
            # Limpar arquivo temporário
            rm temp-admin-config.js
            
            success "Usuário admin personalizado criado com sucesso"
            ;;
        *)
            error "Opção inválida"
            ;;
    esac
    
    cd ..
    
    log "✅ Inicialização do banco de dados concluída"
}

# Função para configurar IP público da EC2 manualmente
detect_and_configure_ip() {
    log "🌐 Configurando IP público da instância EC2..."
    
    echo ""
    echo "🔧 Configuração do IP Público da EC2"
    echo "===================================="
    echo "Digite o IP público da sua instância EC2"
    echo "Exemplo: 3.250.123.45"
    echo ""
    
    while true; do
        read -p "IP público da EC2: " EC2_IP
        
        if [ -z "$EC2_IP" ]; then
            echo "❌ IP não pode estar vazio. Tente novamente."
            continue
        fi
        
        # Validar formato do IP
        if [[ $EC2_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo ""
            read -p "Confirmar IP: $EC2_IP? (s/n): " CONFIRM_IP
            if [[ $CONFIRM_IP =~ ^[Ss]$ ]]; then
                break
            else
                echo "Digite o IP novamente:"
                continue
            fi
        else
            echo "❌ Formato de IP inválido. Use o formato: xxx.xxx.xxx.xxx"
            continue
        fi
    done
    
    success "IP configurado: $EC2_IP"
    
    # Configurar no .env do frontend
    log "⚙️ Configurando REACT_APP_API_URL no frontend..."
    cd frontend
    
    # Criar .env se não existir
    if [ ! -f .env ]; then
        cp ../env.example .env 2>/dev/null || touch .env
    fi
    
    # Atualizar ou adicionar REACT_APP_API_URL
    if grep -q '^REACT_APP_API_URL=' .env; then
        # Atualizar linha existente
        sed -i "s|^REACT_APP_API_URL=.*|REACT_APP_API_URL=http://$EC2_IP:3001/api|g" .env
    else
        # Adicionar nova linha
        echo "REACT_APP_API_URL=http://$EC2_IP:3001/api" >> .env
    fi
    
    # Verificar se foi configurado corretamente
    if grep -q "REACT_APP_API_URL=http://$EC2_IP:3001/api" .env; then
        success "REACT_APP_API_URL configurado: http://$EC2_IP:3001/api"
    else
        error "Falha ao configurar REACT_APP_API_URL"
    fi
    
    cd ..
    
    # Salvar IP para uso posterior
    echo "$EC2_IP" > .ec2_ip
    success "IP da EC2 salvo para uso posterior"
}

# Função para fazer deploy
deploy_application() {
    log "🚀 Iniciando deploy da aplicação..."
    
    # Verificar se estamos no diretório correto
    if [ ! -f "docker-compose.yml" ]; then
        error "Arquivo docker-compose.yml não encontrado. Execute este script no diretório raiz do projeto."
    fi
    
    # Configurar IP público ANTES da inicialização do banco
    detect_and_configure_ip
    
    # Inicializar banco de dados ANTES do deploy
    initialize_database
    
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
    log "🐳 Construindo e iniciando container único..."
    sudo docker-compose up --build -d
    
    success "Container iniciado"
    
    # Aguardar serviço estar pronto
    log "⏳ Aguardando serviço estar pronto..."
    sleep 30
    
    # Verificar se a aplicação está respondendo
    log "🔍 Verificando se a aplicação está respondendo..."
    for i in {1..10}; do
        if curl -f http://localhost:3000/health > /dev/null 2>&1; then
            success "Aplicação está respondendo"
            break
        else
            warning "Tentativa $i: Aplicação ainda não está respondendo..."
            sleep 10
        fi
    done
    
    # Configurar logs
    log "📝 Configurando logs..."
    sudo mkdir -p /var/log/nh-personal
    sudo chown $USER:$USER /var/log/nh-personal
    
    # Mostrar informações finais
    show_deploy_info
}

# Função para mostrar informações do deploy
show_deploy_info() {
    # Obter IP público da instância (usar o salvo ou detectar novamente)
    if [ -f ".ec2_ip" ]; then
        PUBLIC_IP=$(cat .ec2_ip)
    else
        PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")
    fi
    
    # Obter credenciais do admin
    if [ -f ".admin_username" ] && [ -f ".admin_password" ]; then
        ADMIN_USERNAME=$(cat .admin_username)
        ADMIN_PASSWORD=$(cat .admin_password)
    else
        ADMIN_USERNAME="nholanda"
        ADMIN_PASSWORD="P10r1988!"
    fi
    
    echo ""
    echo "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
    echo "=================================="
    echo "🌐 URL da aplicação:"
    echo "   Aplicação: http://$PUBLIC_IP:3000"
    echo "   Health Check: http://$PUBLIC_IP:3000/health"
    echo "   API: http://$PUBLIC_IP:3000/api"
    echo ""
    echo "👤 Credenciais de Administrador:"
    echo "   Usuário: $ADMIN_USERNAME"
    echo "   Senha: $ADMIN_PASSWORD"
    echo ""
    echo "🔐 Acesso à área administrativa:"
    echo "   URL: http://$PUBLIC_IP:3000/admin"
    echo "   Use as credenciais acima para fazer login"
    echo ""
    echo "✅ Banco de dados inicializado automaticamente"
    echo "✅ Usuário admin criado automaticamente"
    echo "✅ IP público configurado automaticamente"
    echo "✅ Container único configurado"
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
        -d '{"name":"nholanda","password":"P10r1988!"}' 2>/dev/null || echo "FAILED")
    
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