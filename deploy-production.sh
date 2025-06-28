#!/bin/bash

# Script de Deploy para Produção - NH Personal Trainer
# Atualizado com correções para problemas de build

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    error "Docker não está instalado"
    exit 1
fi

# Verificar se Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose não está instalado"
    exit 1
fi

log "🚀 Iniciando deploy da aplicação NH Personal Trainer..."

# Parar containers existentes
log "🛑 Parando containers existentes..."
docker-compose down --remove-orphans

# Limpar imagens antigas
log "🧹 Limpando imagens antigas..."
docker system prune -f

# Construir imagens
log "🔨 Construindo imagens Docker..."

# Construir backend primeiro
log "📦 Construindo backend..."
docker build -t personal-backend ./backend

# Verificar se o build do backend foi bem-sucedido
if [ $? -eq 0 ]; then
    success "Backend construído com sucesso"
else
    error "Falha na construção do backend"
    exit 1
fi

# Construir frontend
log "📦 Construindo frontend..."
docker build -t personal-frontend ./frontend

if [ $? -eq 0 ]; then
    success "Frontend construído com sucesso"
else
    error "Falha na construção do frontend"
    exit 1
fi

# Iniciar serviços
log "🚀 Iniciando serviços..."
docker-compose up -d

# Aguardar um pouco para os serviços inicializarem
log "⏳ Aguardando inicialização dos serviços..."
sleep 10

# Verificar status dos containers
log "📊 Verificando status dos containers..."
docker-compose ps

# Verificar logs do backend
log "📋 Verificando logs do backend..."
docker-compose logs backend

# Verificar logs do frontend
log "📋 Verificando logs do frontend..."
docker-compose logs frontend

# Verificar logs do nginx
log "📋 Verificando logs do nginx..."
docker-compose logs nginx

# Testar health check
log "🏥 Testando health check..."
sleep 5

if curl -f http://localhost/health > /dev/null 2>&1; then
    success "Health check passou!"
else
    warn "Health check falhou, mas os serviços podem estar ainda inicializando"
fi

success "🎉 Deploy concluído!"
log "📱 Aplicação disponível em: http://localhost"
log "🔗 Health check: http://localhost/health"
log "📚 API: http://localhost/api"

# Mostrar informações finais
echo ""
echo "📋 Informações do Deploy:"
echo "   - Backend: http://localhost:3001"
echo "   - Frontend: http://localhost:3000"
echo "   - Nginx: http://localhost"
echo "   - MySQL: localhost:3306"
echo ""
echo "🔍 Para ver logs em tempo real:"
echo "   docker-compose logs -f"
echo ""
echo "🛑 Para parar os serviços:"
echo "   docker-compose down"

# Adicionar o comando para iniciar uma sessão SSM
echo ""
echo "📋 Comandos úteis:"
echo "   • Ver logs: docker-compose logs -f"
echo "   • Reiniciar: docker-compose restart"
echo "   • Parar: docker-compose down"

chmod +x deploy-ec2.sh
./deploy-ec2.sh 