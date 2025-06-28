#!/bin/bash

# Script de Deploy para EC2 com RDS - NH Personal Trainer
set -e

echo "🚀 Iniciando deploy na EC2 com RDS..."

# Verificar se o arquivo .env existe
if [ ! -f ".env" ]; then
    echo "❌ Arquivo .env não encontrado!"
    echo "📋 Copie o env.example e configure as variáveis do RDS:"
    echo "   cp env.example .env"
    echo "   nano .env"
    exit 1
fi

# Carregar variáveis de ambiente
source .env

# Verificar variáveis obrigatórias
if [ -z "$RDS_HOST" ] && [ -z "$AWS_SECRET_NAME" ]; then
    echo "❌ Configure RDS_HOST ou AWS_SECRET_NAME no arquivo .env"
    exit 1
fi

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down --remove-orphans

# Limpar imagens antigas
echo "🧹 Limpando imagens antigas..."
docker system prune -f

# Construir backend
echo "🔨 Construindo backend..."
cd backend
docker build -t personal-backend .
cd ..

if [ $? -eq 0 ]; then
    echo "✅ Backend construído com sucesso"
else
    echo "❌ Falha na construção do backend"
    exit 1
fi

# Construir frontend
echo "🔨 Construindo frontend..."
cd frontend
docker build -t personal-frontend .
cd ..

if [ $? -eq 0 ]; then
    echo "✅ Frontend construído com sucesso"
else
    echo "❌ Falha na construção do frontend"
    exit 1
fi

# Iniciar serviços
echo "🚀 Iniciando serviços..."
docker-compose up -d

# Aguardar inicialização
echo "⏳ Aguardando inicialização dos serviços..."
sleep 20

# Verificar status
echo "📊 Status dos containers:"
docker-compose ps

# Verificar logs
echo "📋 Logs do backend:"
docker-compose logs backend

echo "📋 Logs do frontend:"
docker-compose logs frontend

# Testar health check
echo "🏥 Testando health check..."
sleep 10

if curl -f http://localhost:3001/health > /dev/null 2>&1; then
    echo "✅ Health check passou!"
else
    echo "⚠️ Health check falhou, mas os serviços podem estar ainda inicializando"
fi

echo "🎉 Deploy concluído!"
echo "📱 Aplicação disponível em:"
echo "   • Frontend: http://localhost:3000"
echo "   • Backend API: http://localhost:3001"
echo "   • Health Check: http://localhost:3001/health"

# Mostrar informações finais
echo ""
echo "📋 Informações do Deploy:"
echo "   - Backend: http://localhost:3001"
echo "   - Frontend: http://localhost:3000"
echo "   - RDS: $RDS_HOST"
echo ""
echo "🔍 Para ver logs em tempo real:"
echo "   docker-compose logs -f"
echo ""
echo "🛑 Para parar os serviços:"
echo "   docker-compose down" 