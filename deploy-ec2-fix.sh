#!/bin/bash

# Script de Deploy para EC2 - Correção dos problemas de build
set -e

echo "🚀 Iniciando correção do deploy na EC2..."

# Parar todos os containers
echo "🛑 Parando containers..."
docker-compose down --remove-orphans

# Limpar imagens antigas
echo "🧹 Limpando imagens antigas..."
docker system prune -f

# Construir backend com as correções
echo "🔨 Construindo backend..."
cd backend
docker build -t personal-backend .
cd ..

# Verificar se o build foi bem-sucedido
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

# Verificar se o build foi bem-sucedido
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
echo "⏳ Aguardando inicialização..."
sleep 15

# Verificar status
echo "📊 Status dos containers:"
docker-compose ps

# Verificar logs
echo "📋 Logs do backend:"
docker-compose logs backend

echo "📋 Logs do frontend:"
docker-compose logs frontend

echo "📋 Logs do nginx:"
docker-compose logs nginx

echo "🎉 Deploy corrigido!"
echo "📱 Aplicação disponível em: http://localhost"
echo "🔗 Health check: http://localhost/health" 