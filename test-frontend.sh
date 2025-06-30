#!/bin/bash

echo "🧪 TESTE DO FRONTEND"
echo "===================="
echo ""

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Execute este script no diretório raiz do projeto"
    exit 1
fi

echo "📋 1. Verificando se o frontend pode ser buildado..."
cd frontend

if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependências do frontend..."
    npm install
fi

echo "🔨 Fazendo build do frontend..."
if npm run build; then
    echo "✅ Build do frontend concluído com sucesso!"
else
    echo "❌ Erro no build do frontend"
    exit 1
fi

cd ..

echo ""
echo "📋 2. Verificando arquivos gerados..."
if [ -d "frontend/build" ]; then
    echo "✅ Diretório build criado"
    echo "📄 Arquivos no build:"
    ls -la frontend/build/
    
    if [ -f "frontend/build/index.html" ]; then
        echo "✅ index.html encontrado"
        echo "📄 Conteúdo do index.html:"
        head -15 frontend/build/index.html
    else
        echo "❌ index.html não encontrado"
    fi
else
    echo "❌ Diretório build não foi criado"
fi

echo ""
echo "📋 3. Testando servidor local..."
echo "🚀 Iniciando servidor de teste..."
cd frontend/build
python3 -m http.server 8080 &
SERVER_PID=$!

sleep 3

echo "🔍 Testando servidor..."
if curl -f http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ Servidor local funcionando"
    echo "📄 Resposta:"
    curl -s http://localhost:8080 | head -10
else
    echo "❌ Servidor local não está funcionando"
fi

# Parar servidor
kill $SERVER_PID 2>/dev/null

cd ../..

echo ""
echo "🎯 PRÓXIMOS PASSOS:"
echo "==================="
echo "1. Se o build funcionou: ./deploy-ubuntu-ec2.sh deploy"
echo "2. Se há erros no build: Verificar dependências do frontend"
echo "3. Para testar no servidor: ./diagnose-frontend.sh" 