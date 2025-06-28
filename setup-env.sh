#!/bin/bash

# Script para configurar ambiente e resolver problemas
echo "🔧 Configurando ambiente..."

# Verificar se o arquivo .env existe
if [ ! -f ".env" ]; then
    echo "📋 Criando arquivo .env..."
    cp env.example .env
    echo "✅ Arquivo .env criado"
else
    echo "✅ Arquivo .env já existe"
fi

# Remover containers órfãos
echo "🧹 Removendo containers órfãos..."
docker-compose down --remove-orphans

# Remover container MySQL órfão especificamente
echo "🗑️ Removendo container MySQL órfão..."
docker rm -f personal_trainer_mysql 2>/dev/null || echo "Container MySQL não encontrado"

# Limpar volumes não utilizados
echo "🧹 Limpando volumes não utilizados..."
docker volume prune -f

# Verificar se as variáveis estão configuradas
echo "🔍 Verificando variáveis de ambiente..."

# Carregar variáveis do .env
if [ -f ".env" ]; then
    source .env
fi

# Verificar variáveis críticas
echo "📋 Status das variáveis:"

if [ -n "$AWS_SECRET_NAME" ]; then
    echo "   ✅ AWS_SECRET_NAME: Configurado"
else
    echo "   ❌ AWS_SECRET_NAME: Não configurado"
fi

if [ -n "$RDS_HOST" ]; then
    echo "   ✅ RDS_HOST: Configurado"
else
    echo "   ❌ RDS_HOST: Não configurado"
fi

if [ -n "$RDS_USERNAME" ]; then
    echo "   ✅ RDS_USERNAME: Configurado"
else
    echo "   ❌ RDS_USERNAME: Não configurado"
fi

if [ -n "$RDS_PASSWORD" ]; then
    echo "   ✅ RDS_PASSWORD: Configurado"
else
    echo "   ❌ RDS_PASSWORD: Não configurado"
fi

if [ -n "$RDS_DATABASE" ]; then
    echo "   ✅ RDS_DATABASE: Configurado"
else
    echo "   ❌ RDS_DATABASE: Não configurado"
fi

echo ""
echo "📝 Para configurar as variáveis, edite o arquivo .env:"
echo "   nano .env"
echo ""
echo "🔧 Exemplo de configuração mínima:"
echo ""
echo "# Opção A: AWS Secrets Manager (recomendado)"
echo "AWS_SECRET_NAME=rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811"
echo "AWS_REGION=us-east-2"
echo ""
echo "# Opção B: RDS direto"
echo "RDS_HOST=your-rds-endpoint.amazonaws.com"
echo "RDS_USERNAME=admin"
echo "RDS_PASSWORD=your-password"
echo "RDS_DATABASE=personal_trainer_db"
echo ""
echo "🚀 Após configurar, execute:"
echo "   docker-compose up -d --build" 