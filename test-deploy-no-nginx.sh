#!/bin/bash

# Script para testar deploy sem nginx
echo "🧪 Testando deploy sem nginx..."

# Parar todos os containers
echo "🛑 Parando containers..."
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
sleep 30

# Verificar status
echo "📊 Status dos containers:"
docker-compose ps

# Verificar se há containers reiniciando
echo "🔍 Verificando se há containers reiniciando..."
if docker-compose ps | grep -q "Restarting"; then
    echo "❌ Há containers reiniciando!"
    echo "📋 Logs dos containers:"
    docker-compose logs --tail=20
else
    echo "✅ Todos os containers estão estáveis"
fi

# Verificar logs
echo "📋 Logs do backend:"
docker-compose logs backend --tail=10

echo "📋 Logs do frontend:"
docker-compose logs frontend --tail=10

# Testar endpoints
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
echo "🎉 Teste concluído!"
echo "📱 URLs da aplicação:"
echo "   • Frontend: http://localhost:3000"
echo "   • Backend: http://localhost:3001"
echo "   • Health Check: http://localhost:3001/health"

echo ""
echo "📋 Para monitorar em tempo real:"
echo "   docker-compose logs -f"
echo ""
echo "📋 Para verificar status:"
echo "   docker-compose ps" 