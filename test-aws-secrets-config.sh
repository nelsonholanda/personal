#!/bin/bash

# NH-Personal - Script de Teste de Configuração AWS Secrets Manager
# Verifica se todos os arquivos estão configurados corretamente

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

# Função para verificar se um arquivo contém AWS Secrets Manager
check_aws_secrets_in_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        if grep -q "AWS.*SECRET" "$file" || grep -q "aws.*secret" "$file" || grep -q "Secrets Manager" "$file"; then
            log "✅ $description: Configurado para usar AWS Secrets Manager"
            return 0
        else
            warn "⚠️ $description: Não encontrou configuração do AWS Secrets Manager"
            return 1
        fi
    else
        error "❌ $description: Arquivo não encontrado"
        return 1
    fi
}

# Função para verificar se um arquivo tem credenciais hardcoded
check_hardcoded_credentials() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        if grep -q "rootpassword\|app_password\|personal-db.cbkc0cg2c7in" "$file"; then
            warn "⚠️ $description: Encontrou credenciais hardcoded"
            return 1
        else
            log "✅ $description: Sem credenciais hardcoded"
            return 0
        fi
    else
        error "❌ $description: Arquivo não encontrado"
        return 1
    fi
}

# Função principal
main() {
    log "Iniciando verificação de configuração do AWS Secrets Manager..."
    echo ""
    
    local total_files=0
    local configured_files=0
    local no_hardcoded_files=0
    
    # Lista de arquivos para verificar
    declare -a files=(
        "backend/src/index.ts:Backend (index.ts)"
        "backend/src/services/awsSecretsManager.ts:Backend (awsSecretsManager.ts)"
        "test-rds-connection.sh:Script de teste de conexão"
        "init-database.sh:Script de inicialização do banco"
        "install-dependencies.sh:Script de instalação"
        "start.sh:Script de inicialização"
        "aws-userdata.sh:Script de userdata AWS"
        "docker-compose.yml:Docker Compose (desenvolvimento)"
        "docker-compose.prod.yml:Docker Compose (produção)"
        "env.example:Arquivo de exemplo de ambiente"
    )
    
    # Verificar cada arquivo
    for file_info in "${files[@]}"; do
        IFS=':' read -r file description <<< "$file_info"
        total_files=$((total_files + 1))
        
        echo "🔍 Verificando: $description"
        
        # Verificar se está configurado para AWS Secrets Manager
        if check_aws_secrets_in_file "$file" "$description"; then
            configured_files=$((configured_files + 1))
        fi
        
        # Verificar se não tem credenciais hardcoded
        if check_hardcoded_credentials "$file" "$description"; then
            no_hardcoded_files=$((no_hardcoded_files + 1))
        fi
        
        echo ""
    done
    
    # Resumo
    echo "=============================================="
    log "Resumo da verificação:"
    echo ""
    echo "📊 Total de arquivos verificados: $total_files"
    echo "✅ Arquivos configurados para AWS Secrets Manager: $configured_files/$total_files"
    echo "✅ Arquivos sem credenciais hardcoded: $no_hardcoded_files/$total_files"
    echo ""
    
    if [ $configured_files -eq $total_files ] && [ $no_hardcoded_files -eq $total_files ]; then
        log "🎉 Todos os arquivos estão configurados corretamente!"
        echo ""
        echo "✅ AWS Secrets Manager está configurado em todos os arquivos"
        echo "✅ Nenhuma credencial hardcoded encontrada"
        echo ""
        echo "📋 Próximos passos:"
        echo "   1. Configure suas credenciais AWS no arquivo .env"
        echo "   2. Atualize o secret no AWS Secrets Manager"
        echo "   3. Teste a conexão com: ./test-rds-connection.sh"
        echo "   4. Execute a aplicação: ./start.sh"
    else
        warn "⚠️ Alguns arquivos precisam de ajustes"
        echo ""
        echo "📋 Arquivos que precisam ser verificados:"
        echo "   - Verifique se todos os arquivos estão usando AWS Secrets Manager"
        echo "   - Remova credenciais hardcoded restantes"
        echo "   - Configure as variáveis de ambiente corretamente"
    fi
    
    echo ""
    echo "🔐 Para configurar o AWS Secrets Manager:"
    echo "   aws secretsmanager update-secret \\"
    echo "     --secret-id rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811 \\"
    echo "     --region us-east-2 \\"
    echo "     --secret-string '{\"host\":\"seu-host\",\"port\":3306,\"username\":\"seu-user\",\"password\":\"sua-senha\",\"database\":\"personal_trainer_db\"}'"
}

# Executar função principal
main "$@" 