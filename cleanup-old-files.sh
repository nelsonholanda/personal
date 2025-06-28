#!/bin/bash

# Script para limpar arquivos antigos e desnecessários
echo "🧹 Limpando arquivos antigos e desnecessários..."

# Lista de arquivos para remover (scripts antigos)
files_to_remove=(
    "deploy-ec2.sh"
    "deploy-amazon-linux-2023.sh"
    "deploy-amazon-linux-2023-no-curl.sh"
    "deploy.sh"
    "deploy-production.sh"
    "deploy-ec2-fix.sh"
    "test-aws-secrets-config.sh"
    "fix-curl-conflict.sh"
    "fix-typescript-errors.sh"
    "install-dependencies.sh"
    "init-database.sh"
    "test-rds-connection.sh"
    "start.sh"
    "aws-userdata.sh"
    "aws-userdata-example.md"
    "aws-secrets-setup.md"
    "AMAZON_LINUX_2023_README.md"
    "DEPLOY_AMAZON_LINUX_CHANGES.md"
    "CURL_CONFLICT_SOLUTION.md"
    "PRODUCTION_README.md"
    "SCRIPTS_README.md"
    "API_DOCUMENTATION.md"
)

# Lista de arquivos para manter
files_to_keep=(
    "deploy-ec2-rds.sh"
    "test-backend-build.sh"
    "RDS_DEPLOY_README.md"
    "README.md"
    "env.example"
    "docker-compose.yml"
    ".gitignore"
    ".editorconfig"
    ".prettierrc"
)

echo "📋 Arquivos que serão removidos:"
for file in "${files_to_remove[@]}"; do
    if [ -f "$file" ]; then
        echo "   ❌ $file"
    fi
done

echo ""
echo "📋 Arquivos que serão mantidos:"
for file in "${files_to_keep[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    fi
done

echo ""
read -p "Deseja continuar com a limpeza? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️ Removendo arquivos..."
    
    for file in "${files_to_remove[@]}"; do
        if [ -f "$file" ]; then
            rm "$file"
            echo "   ✅ Removido: $file"
        fi
    done
    
    echo ""
    echo "🎉 Limpeza concluída!"
    echo ""
    echo "📋 Arquivos essenciais mantidos:"
    echo "   • deploy-ec2-rds.sh - Script principal de deploy"
    echo "   • test-backend-build.sh - Teste de build do backend"
    echo "   • RDS_DEPLOY_README.md - Documentação do deploy"
    echo "   • docker-compose.yml - Configuração do Docker"
    echo "   • env.example - Exemplo de variáveis de ambiente"
    echo ""
    echo "🚀 Para fazer deploy:"
    echo "   ./deploy-ec2-rds.sh"
else
    echo "❌ Limpeza cancelada"
fi 