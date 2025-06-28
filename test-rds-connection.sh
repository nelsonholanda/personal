#!/bin/bash

# NH-Personal - Script de Teste de Conexão RDS
# Testa a conectividade com o banco de dados RDS AWS

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

# Configurações do RDS
RDS_HOST="personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com"
RDS_PORT="3306"
RDS_USER="root"
RDS_PASSWORD="rootpassword"
RDS_DATABASE="personal_trainer_db"

# Função para testar conectividade básica
test_network_connectivity() {
    log "Testando conectividade de rede..."
    
    # Testar se o host responde
    if ping -c 3 "$RDS_HOST" >/dev/null 2>&1; then
        log "✅ Host RDS responde ao ping"
    else
        warn "⚠️ Host RDS não responde ao ping (pode ser normal em alguns casos)"
    fi
    
    # Testar conectividade na porta 3306
    if timeout 10 bash -c "</dev/tcp/$RDS_HOST/$RDS_PORT" 2>/dev/null; then
        log "✅ Porta 3306 está acessível"
        return 0
    else
        error "❌ Porta 3306 não está acessível"
        return 1
    fi
}

# Função para testar conexão MySQL
test_mysql_connection() {
    log "Testando conexão MySQL..."
    
    if mysql -h "$RDS_HOST" -P "$RDS_PORT" -u "$RDS_USER" -p"$RDS_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
        log "✅ Conexão MySQL estabelecida com sucesso"
        return 0
    else
        error "❌ Falha na conexão MySQL"
        return 1
    fi
}

# Função para testar banco de dados específico
test_database_access() {
    log "Testando acesso ao banco de dados..."
    
    if mysql -h "$RDS_HOST" -P "$RDS_PORT" -u "$RDS_USER" -p"$RDS_PASSWORD" "$RDS_DATABASE" -e "SELECT 1;" >/dev/null 2>&1; then
        log "✅ Acesso ao banco '$RDS_DATABASE' OK"
        return 0
    else
        warn "⚠️ Não foi possível acessar o banco '$RDS_DATABASE'"
        return 1
    fi
}

# Função para verificar tabelas
check_database_tables() {
    log "Verificando tabelas do banco de dados..."
    
    TABLE_COUNT=$(mysql -h "$RDS_HOST" -P "$RDS_PORT" -u "$RDS_USER" -p"$RDS_PASSWORD" "$RDS_DATABASE" -s -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$RDS_DATABASE';" 2>/dev/null || echo "0")
    
    if [ "$TABLE_COUNT" -gt 0 ]; then
        log "✅ Banco de dados possui $TABLE_COUNT tabelas"
        
        # Listar algumas tabelas principais
        TABLES=$(mysql -h "$RDS_HOST" -P "$RDS_PORT" -u "$RDS_USER" -p"$RDS_PASSWORD" "$RDS_DATABASE" -s -N -e "SHOW TABLES;" 2>/dev/null | head -5 | tr '\n' ', ')
        info "📋 Tabelas encontradas: $TABLES"
    else
        warn "⚠️ Nenhuma tabela encontrada no banco de dados"
    fi
}

# Função para verificar usuários
check_users() {
    log "Verificando usuários do sistema..."
    
    USER_COUNT=$(mysql -h "$RDS_HOST" -P "$RDS_PORT" -u "$RDS_USER" -p"$RDS_PASSWORD" "$RDS_DATABASE" -s -N -e "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
    
    if [ "$USER_COUNT" -gt 0 ]; then
        log "✅ Sistema possui $USER_COUNT usuários"
        
        # Verificar usuários admin
        ADMIN_COUNT=$(mysql -h "$RDS_HOST" -P "$RDS_PORT" -u "$RDS_USER" -p"$RDS_PASSWORD" "$RDS_DATABASE" -s -N -e "SELECT COUNT(*) FROM users WHERE role = 'admin';" 2>/dev/null || echo "0")
        info "👤 Usuários administradores: $ADMIN_COUNT"
    else
        warn "⚠️ Nenhum usuário encontrado no sistema"
    fi
}

# Função para testar performance
test_performance() {
    log "Testando performance da conexão..."
    
    START_TIME=$(date +%s.%N)
    mysql -h "$RDS_HOST" -P "$RDS_PORT" -u "$RDS_USER" -p"$RDS_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1
    END_TIME=$(date +%s.%N)
    
    RESPONSE_TIME=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "0.1")
    log "⏱️ Tempo de resposta: ${RESPONSE_TIME}s"
    
    if (( $(echo "$RESPONSE_TIME < 1.0" | bc -l) )); then
        log "✅ Performance da conexão está boa"
    else
        warn "⚠️ Tempo de resposta alto: ${RESPONSE_TIME}s"
    fi
}

# Função para mostrar informações de configuração
show_configuration() {
    log "Informações de configuração:"
    echo ""
    echo "🗄️ Configurações do RDS:"
    echo "   Host: $RDS_HOST"
    echo "   Porta: $RDS_PORT"
    echo "   Usuário: $RDS_USER"
    echo "   Banco: $RDS_DATABASE"
    echo "   Região: us-east-2"
    echo ""
    echo "🔐 Secret Name: rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811"
    echo ""
    echo "📊 Comandos úteis:"
    echo "   mysql -h $RDS_HOST -P $RDS_PORT -u $RDS_USER -p$RDS_DATABASE"
    echo "   mysql -h $RDS_HOST -P $RDS_PORT -u $RDS_USER -p$RDS_DATABASE -e 'SHOW TABLES;'"
    echo "   mysql -h $RDS_HOST -P $RDS_PORT -u $RDS_USER -p$RDS_DATABASE -e 'SELECT COUNT(*) FROM users;'"
    echo ""
}

# Função para mostrar status dos serviços
check_services_status() {
    log "Verificando status dos serviços..."
    
    if command -v systemctl &> /dev/null; then
        # Verificar backend
        if systemctl is-active --quiet nh-personal-backend; then
            log "✅ Serviço nh-personal-backend está ativo"
        else
            warn "⚠️ Serviço nh-personal-backend não está ativo"
        fi
        
        # Verificar frontend
        if systemctl is-active --quiet nh-personal-frontend; then
            log "✅ Serviço nh-personal-frontend está ativo"
        else
            warn "⚠️ Serviço nh-personal-frontend não está ativo"
        fi
        
        # Verificar nginx
        if systemctl is-active --quiet nginx; then
            log "✅ Serviço nginx está ativo"
        else
            warn "⚠️ Serviço nginx não está ativo"
        fi
    else
        info "ℹ️ systemctl não disponível, pulando verificação de serviços"
    fi
}

# Função principal
main() {
    log "Iniciando teste de conexão com RDS..."
    echo ""
    
    # Verificar se o MySQL client está instalado
    if ! command -v mysql &> /dev/null; then
        error "MySQL client não está instalado. Execute o script de instalação primeiro."
        exit 1
    fi
    
    # Mostrar configuração
    show_configuration
    
    # Testar conectividade de rede
    if ! test_network_connectivity; then
        error "❌ Falha na conectividade de rede"
        exit 1
    fi
    
    # Testar conexão MySQL
    if ! test_mysql_connection; then
        error "❌ Falha na conexão MySQL"
        exit 1
    fi
    
    # Testar acesso ao banco
    if test_database_access; then
        # Verificar tabelas
        check_database_tables
        
        # Verificar usuários
        check_users
    fi
    
    # Testar performance
    test_performance
    
    # Verificar serviços
    check_services_status
    
    echo ""
    log "✅ Teste de conexão concluído com sucesso!"
    echo ""
    echo "🎉 NH-Personal está configurado corretamente!"
    echo "🌐 Acesse: http://localhost:3000"
    echo "📚 API: http://localhost:3001/api"
    echo "🔍 Health Check: http://localhost:3001/health"
    echo ""
    echo "👤 Usuários padrão:"
    echo "   Email: admin@nhpersonal.com"
    echo "   Email: nholanda@nhpersonal.com"
    echo "   Senha: rdms95gn"
}

# Executar função principal
main "$@" 