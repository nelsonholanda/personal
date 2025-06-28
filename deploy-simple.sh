#!/bin/bash

# Script de Deploy Simplificado - NH Personal Trainer
set -e

echo "🚀 Deploy Simplificado - NH Personal Trainer"

# 1. Verificar se o arquivo .env existe
if [ ! -f ".env" ]; then
    echo "📋 Criando arquivo .env..."
    ./create-env.sh
    echo ""
    echo "❌ Configure as variáveis do RDS no arquivo .env antes de continuar!"
    echo "   nano .env"
    exit 1
fi

# 2. Carregar variáveis de ambiente
source .env

# 3. Verificar variáveis críticas
echo "🔍 Verificando configurações..."

if [ -z "$RDS_HOST" ] && [ -z "$AWS_SECRET_NAME" ]; then
    echo "❌ Configure RDS_HOST ou AWS_SECRET_NAME no arquivo .env"
    echo "   nano .env"
    exit 1
fi

# 4. Limpar ambiente
echo "🧹 Limpando ambiente..."
docker-compose down --remove-orphans
docker rm -f personal_trainer_mysql 2>/dev/null || true
docker system prune -f

# 5. Construir imagens
echo "🔨 Construindo imagens..."

echo "📦 Construindo backend..."
cd backend
docker build -t personal-backend .
cd ..

echo "📦 Construindo frontend..."
cd frontend
docker build -t personal-frontend .
cd ..

# 6. Iniciar serviços
echo "🚀 Iniciando serviços..."
docker-compose up -d

# 7. Aguardar inicialização
echo "⏳ Aguardando inicialização..."
sleep 30

# 8. Verificar status
echo "📊 Status dos containers:"
docker-compose ps

# 9. Verificar se há containers reiniciando
if docker-compose ps | grep -q "Restarting"; then
    echo "❌ Há containers reiniciando!"
    echo "📋 Logs dos containers:"
    docker-compose logs --tail=20
else
    echo "✅ Todos os containers estão estáveis"
fi

# 10. Testar endpoints
echo "🏥 Testando endpoints..."
sleep 10

# Testar backend
if curl -f http://localhost:3001/health > /dev/null 2>&1; then
    echo "✅ Backend health check: OK"
else
    echo "❌ Backend health check: FALHOU"
fi

# Testar frontend
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Frontend: OK"
else
    echo "❌ Frontend: FALHOU"
fi

echo ""
echo "🎉 Deploy concluído!"
echo "📱 URLs da aplicação:"
echo "   • Frontend: http://localhost:3000"
echo "   • Backend API: http://localhost:3001"
echo "   • Health Check: http://localhost:3001/health"

echo ""
echo "📋 Comandos úteis:"
echo "   • Ver logs: docker-compose logs -f"
echo "   • Ver status: docker-compose ps"
echo "   • Parar: docker-compose down"
echo "   • Reiniciar: docker-compose restart" 