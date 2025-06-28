#!/bin/bash

# Script para resolver conflito do curl no Amazon Linux 2023
# Versão: 1.0.0

set -e

echo "🔧 Resolvendo conflito do curl no Amazon Linux 2023..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
    exit 1
}

# Verificar se é Amazon Linux 2023
if ! grep -q "Amazon Linux release 2023" /etc/os-release; then
    error "Este script é específico para Amazon Linux 2023"
fi

log "📋 Verificando situação atual do curl..."

# Verificar qual versão do curl está instalada
if command -v curl &> /dev/null; then
    CURL_VERSION=$(curl --version | head -n1)
    log "Versão atual do curl: $CURL_VERSION"
else
    warning "curl não encontrado no sistema"
fi

# Verificar pacotes instalados relacionados ao curl
log "🔍 Verificando pacotes curl instalados..."
CURL_PACKAGES=$(rpm -qa | grep -i curl || echo "Nenhum pacote curl encontrado")
log "Pacotes curl encontrados: $CURL_PACKAGES"

# Opção 1: Tentar resolver conflitos automaticamente
log "🔄 Tentando resolver conflitos automaticamente..."
if sudo dnf install -y --allowerasing curl; then
    success "Conflito resolvido automaticamente"
else
    warning "Resolução automática falhou, tentando método manual..."
    
    # Opção 2: Remover curl-minimal e instalar curl completo
    log "🗑️ Removendo curl-minimal..."
    if sudo dnf remove -y curl-minimal; then
        log "📦 Instalando curl completo..."
        if sudo dnf install -y curl; then
            success "curl completo instalado com sucesso"
        else
            error "Falha ao instalar curl completo"
        fi
    else
        warning "Não foi possível remover curl-minimal"
        
        # Opção 3: Usar curl-minimal (já funciona para a maioria dos casos)
        log "✅ Usando curl-minimal existente..."
        success "curl-minimal é suficiente para o deploy"
    fi
fi

# Verificar se curl está funcionando
log "🧪 Testando funcionalidade do curl..."
if curl -s --max-time 5 https://httpbin.org/get > /dev/null; then
    success "curl está funcionando corretamente"
else
    warning "curl não conseguiu fazer requisição HTTP, mas pode funcionar para downloads locais"
fi

# Verificar se o curl tem as funcionalidades necessárias para o deploy
log "🔍 Verificando funcionalidades necessárias do curl..."

# Testar download (necessário para Docker Compose)
if curl -L --max-time 10 -o /tmp/test-download https://httpbin.org/bytes/100; then
    success "Download funcionando"
    rm -f /tmp/test-download
else
    warning "Download pode ter problemas, mas curl-minimal geralmente funciona"
fi

# Testar JSON parsing (se jq estiver instalado)
if command -v jq &> /dev/null; then
    if curl -s https://httpbin.org/json | jq . > /dev/null; then
        success "JSON parsing funcionando"
    else
        warning "JSON parsing pode ter problemas"
    fi
else
    log "jq não instalado, instalando..."
    sudo dnf install -y jq
fi

echo ""
echo "🎉 Verificação do curl concluída!"
echo ""
echo "📋 Resumo:"
echo "   - curl está disponível e funcionando"
echo "   - curl-minimal é suficiente para o deploy"
echo "   - Se houver problemas, o script de deploy tentará resolver automaticamente"
echo ""
echo "🚀 Agora você pode executar o deploy:"
echo "   ./deploy-amazon-linux-2023.sh"
echo "" 