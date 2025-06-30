#!/bin/bash

echo "🔍 DIAGNÓSTICO DO FRONTEND"
echo "=========================="
echo ""

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Execute este script no diretório raiz do projeto"
    exit 1
fi

echo "📋 1. Verificando estrutura do projeto..."
echo "   ✅ docker-compose.yml: $(ls -la docker-compose.yml 2>/dev/null | wc -l)"
echo "   ✅ backend/: $(ls -la backend/ 2>/dev/null | wc -l)"
echo "   ✅ frontend/: $(ls -la frontend/ 2>/dev/null | wc -l)"
echo ""

echo "📋 2. Verificando arquivos .env..."
echo "   ✅ backend/.env: $(ls -la backend/.env 2>/dev/null | wc -l)"
echo "   ✅ frontend/.env: $(ls -la frontend/.env 2>/dev/null | wc -l)"
echo ""

echo "📋 3. Verificando containers..."
if command -v docker &> /dev/null; then
    echo "   ✅ Docker: $(docker --version)"
    if docker compose ps | grep -q "Up"; then
        echo "   ✅ Containers rodando:"
        docker compose ps
    else
        echo "   ❌ Containers não estão rodando"
    fi
else
    echo "   ❌ Docker não instalado"
fi
echo ""

echo "📋 4. Testando conectividade..."
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo "   ✅ Health check: OK"
    HEALTH_RESPONSE=$(curl -s http://localhost:3000/health)
    echo "   📄 Resposta: $HEALTH_RESPONSE"
else
    echo "   ❌ Health check: FALHOU"
fi

if curl -f http://localhost:3000 > /dev/null 2>&1; then
    echo "   ✅ Página inicial: OK"
    FRONTEND_RESPONSE=$(curl -s -I http://localhost:3000 | head -1)
    echo "   📄 Status: $FRONTEND_RESPONSE"
else
    echo "   ❌ Página inicial: FALHOU"
fi
echo ""

echo "📋 5. Verificando logs do container..."
if command -v docker &> /dev/null; then
    echo "   📋 Últimos logs:"
    docker compose logs --tail=10
else
    echo "   ❌ Docker não disponível"
fi
echo ""

echo "📋 6. Verificando build do frontend..."
if [ -d "frontend/build" ]; then
    echo "   ✅ frontend/build existe"
    echo "   📄 Arquivos no build:"
    ls -la frontend/build/
    echo ""
    if [ -f "frontend/build/index.html" ]; then
        echo "   ✅ index.html encontrado"
        echo "   📄 Conteúdo do index.html:"
        head -10 frontend/build/index.html
    else
        echo "   ❌ index.html não encontrado"
    fi
else
    echo "   ❌ frontend/build não existe"
fi
echo ""

echo "📋 7. Verificando variáveis de ambiente..."
if [ -f "backend/.env" ]; then
    echo "   📄 NODE_ENV: $(grep NODE_ENV backend/.env | cut -d'=' -f2)"
    echo "   📄 FRONTEND_URL: $(grep FRONTEND_URL backend/.env | cut -d'=' -f2)"
fi
echo ""

echo "🎯 RECOMENDAÇÕES:"
echo "================="
echo "1. Se containers não estão rodando: ./deploy-ubuntu-ec2.sh deploy"
echo "2. Se frontend/build não existe: cd frontend && npm run build"
echo "3. Se NODE_ENV não é 'production': Verificar backend/.env"
echo "4. Para ver logs completos: docker compose logs"
echo "5. Para reiniciar: docker compose restart" 