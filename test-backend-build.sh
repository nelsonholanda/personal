#!/bin/bash

# Script para testar o build do backend
set -e

echo "🔨 Testando build do backend..."

# Verificar se estamos no diretório correto
if [ ! -f "backend/package.json" ]; then
    echo "❌ Execute este script no diretório raiz do projeto"
    exit 1
fi

# Entrar no diretório do backend
cd backend

# Limpar build anterior
echo "🧹 Limpando build anterior..."
rm -rf dist/

# Instalar dependências
echo "📦 Instalando dependências..."
npm ci

# Gerar Prisma client
echo "🔧 Gerando Prisma client..."
npx prisma generate

# Executar build
echo "🔨 Executando build..."
npm run build

# Verificar se o build foi bem-sucedido
if [ -f "dist/index.js" ]; then
    echo "✅ Build bem-sucedido! Arquivo dist/index.js criado."
    echo "📁 Conteúdo do diretório dist/:"
    ls -la dist/
else
    echo "❌ Build falhou! Arquivo dist/index.js não foi criado."
    exit 1
fi

echo "🎉 Teste de build concluído com sucesso!" 