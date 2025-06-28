#!/bin/bash

# NH-Personal - Script de Inicialização do Banco de Dados
# Para uso com RDS AWS
# Versão: 2.0.0

set -e

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

# Configurações do AWS Secrets Manager
SECRET_NAME="${1:-rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811}"
AWS_REGION="us-east-2"

# Variáveis para armazenar credenciais do banco
RDS_HOST=""
RDS_PORT=""
RDS_USER=""
RDS_PASSWORD=""
RDS_DATABASE=""

# Função para obter credenciais do AWS Secrets Manager
get_database_credentials() {
    log "Obtendo credenciais do banco de dados..."
    
    # Definir caminho do AWS CLI
    AWS_CLI="/usr/local/bin/aws"
    
    # Verificar se AWS CLI está instalado
    if ! command -v "$AWS_CLI" &> /dev/null; then
        warn "⚠️ AWS CLI não está instalado. Usando credenciais locais como fallback."
        use_local_credentials
        return
    fi
    
    # Verificar se AWS está configurado
    if ! "$AWS_CLI" sts get-caller-identity &> /dev/null; then
        warn "⚠️ AWS CLI não está configurado. Usando credenciais locais como fallback."
        use_local_credentials
        return
    fi
    
    # Obter secret do AWS Secrets Manager
    local secret_json
    if secret_json=$("$AWS_CLI" secretsmanager get-secret-value --secret-id "$SECRET_NAME" --region "$AWS_REGION" --query 'SecretString' --output text 2>/dev/null); then
        log "✅ Secret obtido com sucesso do AWS Secrets Manager"
        
        # Extrair valores do JSON
        RDS_HOST=$(echo "$secret_json" | jq -r '.host // empty')
        RDS_PORT=$(echo "$secret_json" | jq -r '.port // 3306')
        RDS_USER=$(echo "$secret_json" | jq -r '.username // empty')
        RDS_PASSWORD=$(echo "$secret_json" | jq -r '.password // empty')
        RDS_DATABASE=$(echo "$secret_json" | jq -r '.dbname // .database // empty')
        
        # Verificar se todos os campos necessários foram obtidos
        if [[ -z "$RDS_HOST" || -z "$RDS_USER" || -z "$RDS_PASSWORD" || -z "$RDS_DATABASE" ]]; then
            error "❌ Credenciais incompletas obtidas do secret"
            error "Host: $RDS_HOST"
            error "User: $RDS_USER"
            error "Database: $RDS_DATABASE"
            error "Password: [HIDDEN]"
            warn "⚠️ Usando credenciais locais como fallback."
            use_local_credentials
            return
        fi
        
        log "✅ Credenciais extraídas com sucesso"
        info "Host: $RDS_HOST"
        info "Port: $RDS_PORT"
        info "User: $RDS_USER"
        info "Database: $RDS_DATABASE"
        
    else
        error "❌ Falha ao obter secret do AWS Secrets Manager"
        error "Secret Name: $SECRET_NAME"
        error "Region: $AWS_REGION"
        warn "⚠️ Usando credenciais locais como fallback."
        use_local_credentials
    fi
}

# Função para usar credenciais locais como fallback
use_local_credentials() {
    log "Usando credenciais locais..."
    
    # Tentar obter credenciais de variáveis de ambiente
    RDS_HOST="${RDS_HOST:-localhost}"
    RDS_PORT="${RDS_PORT:-3306}"
    RDS_USER="${RDS_USER:-root}"
    RDS_PASSWORD="${RDS_PASSWORD:-password}"
    RDS_DATABASE="${RDS_DATABASE:-personal_trainer_db}"
    
    # Verificar se as credenciais estão definidas
    if [[ -z "$RDS_HOST" || -z "$RDS_USER" || -z "$RDS_PASSWORD" || -z "$RDS_DATABASE" ]]; then
        error "❌ Credenciais locais incompletas"
        error "Defina as seguintes variáveis de ambiente:"
        error "  RDS_HOST, RDS_USER, RDS_PASSWORD, RDS_DATABASE"
        exit 1
    fi
    
    log "✅ Credenciais locais configuradas"
    info "Host: $RDS_HOST"
    info "Port: $RDS_PORT"
    info "User: $RDS_USER"
    info "Database: $RDS_DATABASE"
}

# Função para testar conexão com RDS
test_rds_connection() {
    log "Testando conexão com RDS..."
    
    if mysql -h "$RDS_HOST" -P "$RDS_PORT" -u "$RDS_USER" -p"$RDS_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
        log "✅ Conexão com RDS estabelecida com sucesso"
        return 0
    else
        error "❌ Falha na conexão com RDS"
        return 1
    fi
}

# Função para criar banco de dados
create_database() {
    log "Criando banco de dados..."
    
    mysql -h "$RDS_HOST" -P "$RDS_PORT" -u "$RDS_USER" -p"$RDS_PASSWORD" -e "
        CREATE DATABASE IF NOT EXISTS \`$RDS_DATABASE\` 
        CHARACTER SET utf8mb4 
        COLLATE utf8mb4_unicode_ci;
    "
    
    log "✅ Banco de dados criado/verificado com sucesso"
}

# Função para executar migrações do Prisma
run_prisma_migrations() {
    log "Executando migrações do Prisma..."
    
    cd /opt/nh-personal/backend
    
    # Configurar variável de ambiente para o banco
    export DATABASE_URL="mysql://$RDS_USER:$RDS_PASSWORD@$RDS_HOST:$RDS_PORT/$RDS_DATABASE"
    
    # Gerar cliente Prisma
    npx prisma generate
    
    # Executar migrações
    npx prisma migrate deploy
    
    log "✅ Migrações do Prisma executadas com sucesso"
}

# Função para inserir dados iniciais
insert_initial_data() {
    log "Inserindo dados iniciais..."
    
    # Conectar ao banco e inserir dados básicos
    mysql -h "$RDS_HOST" -P "$RDS_PORT" -u "$RDS_USER" -p"$RDS_PASSWORD" "$RDS_DATABASE" << 'EOF'
-- Inserir usuário administrador
INSERT IGNORE INTO users (
    name, 
    email, 
    password_hash, 
    role, 
    phone, 
    is_active, 
    password_changed_at, 
    created_at, 
    updated_at
) VALUES (
    'Nholanda Admin',
    'admin@nhpersonal.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.iK2i', -- rdms95gn
    'admin',
    '+5511999999999',
    1,
    NOW(),
    NOW(),
    NOW()
);

-- Inserir usuário nholanda
INSERT IGNORE INTO users (
    name, 
    email, 
    password_hash, 
    role, 
    phone, 
    is_active, 
    password_changed_at, 
    created_at, 
    updated_at
) VALUES (
    'Nholanda',
    'nholanda@nhpersonal.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.iK2i', -- rdms95gn
    'admin',
    '+5511999999999',
    1,
    NOW(),
    NOW(),
    NOW()
);

-- Inserir métodos de pagamento padrão
INSERT IGNORE INTO payment_methods (name, description, is_active, created_at) VALUES
('Dinheiro', 'Pagamento em dinheiro', 1, NOW()),
('PIX', 'Pagamento via PIX', 1, NOW()),
('Cartão de Crédito', 'Pagamento com cartão de crédito', 1, NOW()),
('Cartão de Débito', 'Pagamento com cartão de débito', 1, NOW()),
('Transferência Bancária', 'Transferência bancária', 1, NOW()),
('Boleto Bancário', 'Pagamento via boleto', 1, NOW());

-- Inserir planos de pagamento padrão
INSERT IGNORE INTO payment_plans (name, description, price, duration_weeks, sessions_per_week, is_active, created_at) VALUES
('Plano Básico', '3 sessões por semana por 4 semanas', 400.00, 4, 3, 1, NOW()),
('Plano Intermediário', '3 sessões por semana por 8 semanas', 720.00, 8, 3, 1, NOW()),
('Plano Avançado', '4 sessões por semana por 12 semanas', 1200.00, 12, 4, 1, NOW()),
('Plano Premium', '5 sessões por semana por 16 semanas', 1600.00, 16, 5, 1, NOW()),
('Plano Personalizado', 'Sessões personalizadas conforme necessidade', 150.00, 1, 1, 1, NOW());

-- Inserir exercícios padrão
INSERT IGNORE INTO exercises (name, description, muscle_group, difficulty_level, instructions, equipment_needed, is_active, created_at) VALUES
('Flexão de Braço', 'Exercício para peitoral e tríceps', 'Peitoral, Tríceps', 'intermediate', 'Deite-se no chão, apoie as mãos e faça flexões', 'Nenhum', 1, NOW()),
('Agachamento', 'Exercício para pernas e glúteos', 'Quadríceps, Glúteos', 'beginner', 'Fique em pé, flexione os joelhos e agache', 'Nenhum', 1, NOW()),
('Prancha', 'Exercício para core e estabilização', 'Core', 'beginner', 'Mantenha o corpo reto apoiado nos cotovelos', 'Nenhum', 1, NOW()),
('Burpee', 'Exercício completo de alta intensidade', 'Full Body', 'advanced', 'Combine agachamento, flexão e salto', 'Nenhum', 1, NOW()),
('Corrida', 'Exercício cardiovascular', 'Cardio', 'beginner', 'Corra em ritmo constante', 'Nenhum', 1, NOW()),
('Levantamento Terra', 'Exercício para costas e pernas', 'Costas, Quadríceps', 'advanced', 'Levante peso do chão mantendo a coluna reta', 'Barra e pesos', 1, NOW()),
('Supino', 'Exercício para peitoral', 'Peitoral', 'intermediate', 'Deite-se no banco e levante a barra', 'Banco e barra', 1, NOW()),
('Remada', 'Exercício para costas', 'Costas', 'intermediate', 'Puxe o peso em direção ao peito', 'Cabo ou halteres', 1, NOW()),
('Desenvolvimento', 'Exercício para ombros', 'Ombros', 'intermediate', 'Levante pesos acima da cabeça', 'Halteres ou barra', 1, NOW()),
('Abdominal', 'Exercício para abdômen', 'Core', 'beginner', 'Deite-se e levante o tronco', 'Nenhum', 1, NOW());

EOF

    log "✅ Dados iniciais inseridos com sucesso"
}

# Função para verificar integridade do banco
verify_database() {
    log "Verificando integridade do banco de dados..."
    
    # Verificar se as tabelas foram criadas
    TABLE_COUNT=$(mysql -h "$RDS_HOST" -P "$RDS_PORT" -u "$RDS_USER" -p"$RDS_PASSWORD" "$RDS_DATABASE" -s -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$RDS_DATABASE';")
    
    if [ "$TABLE_COUNT" -gt 0 ]; then
        log "✅ Banco de dados verificado: $TABLE_COUNT tabelas encontradas"
    else
        error "❌ Nenhuma tabela encontrada no banco de dados"
        return 1
    fi
    
    # Verificar se o usuário admin foi criado
    ADMIN_COUNT=$(mysql -h "$RDS_HOST" -P "$RDS_PORT" -u "$RDS_USER" -p"$RDS_PASSWORD" "$RDS_DATABASE" -s -N -e "SELECT COUNT(*) FROM users WHERE role = 'admin';")
    
    if [ "$ADMIN_COUNT" -gt 0 ]; then
        log "✅ Usuário administrador encontrado"
    else
        warn "⚠️ Usuário administrador não encontrado"
    fi
}

# Função para mostrar informações do banco
show_database_info() {
    log "Informações do banco de dados:"
    echo ""
    echo "🗄️ Configurações do RDS:"
    echo "   Host: $RDS_HOST"
    echo "   Porta: $RDS_PORT"
    echo "   Usuário: $RDS_USER"
    echo "   Banco: $RDS_DATABASE"
    echo ""
    echo "👤 Usuários administradores:"
    echo "   Email: admin@nhpersonal.com"
    echo "   Email: nholanda@nhpersonal.com"
    echo "   Senha: rdms95gn"
    echo ""
    echo "🔐 Para conectar manualmente:"
    echo "   mysql -h $RDS_HOST -P $RDS_PORT -u $RDS_USER -p$RDS_DATABASE"
    echo ""
    echo "📊 Para verificar tabelas:"
    echo "   mysql -h $RDS_HOST -P $RDS_PORT -u $RDS_USER -p$RDS_DATABASE -e 'SHOW TABLES;'"
    echo ""
}

# Função principal
main() {
    log "Iniciando configuração do banco de dados NH-Personal..."
    
    # Verificar se o MySQL client está instalado
    if ! command -v mysql &> /dev/null; then
        error "MySQL client não está instalado. Execute o script de instalação primeiro."
        exit 1
    fi
    
    # Verificar se jq está instalado (opcional)
    if ! command -v jq &> /dev/null; then
        warn "⚠️ jq não está instalado. Instale para melhor parsing de JSON: sudo apt install jq"
        warn "⚠️ Usando credenciais locais como fallback."
        use_local_credentials
    else
        # Obter credenciais do AWS Secrets Manager
        get_database_credentials
    fi
    
    # Testar conexão
    if ! test_rds_connection; then
        error "Não foi possível conectar ao RDS. Verifique as configurações."
        exit 1
    fi
    
    # Criar banco de dados
    create_database
    
    # Executar migrações do Prisma
    run_prisma_migrations
    
    # Inserir dados iniciais
    insert_initial_data
    
    # Verificar integridade
    verify_database
    
    # Mostrar informações
    show_database_info
    
    log "✅ Configuração do banco de dados concluída com sucesso!"
    echo ""
    echo "🎉 NH-Personal está pronto para uso!"
    echo "🌐 Acesse: http://localhost:3000"
    echo "📚 API: http://localhost:3001/api"
    echo "🔍 Health Check: http://localhost:3001/health"
}

# Executar função principal
main "$@" 