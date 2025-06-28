#!/bin/bash

# Script para criar arquivo .env mínimo
echo "📋 Criando arquivo .env mínimo..."

cat > .env << 'EOF'
# NH-Personal Environment Variables
# Configurações mínimas para deploy

# AWS Configuration
AWS_REGION=us-east-2

# Opção A: AWS Secrets Manager (recomendado)
# Descomente e configure se usar AWS Secrets Manager
# AWS_SECRET_NAME=rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811

# Opção B: RDS direto (configure com seus dados)
# Descomente e configure se usar RDS diretamente
RDS_HOST=your-rds-endpoint.amazonaws.com
RDS_PORT=3306
RDS_USERNAME=admin
RDS_PASSWORD=your-rds-password
RDS_DATABASE=personal_trainer_db

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production

# Server Configuration
NODE_ENV=production
PORT=3001

# Frontend Configuration
REACT_APP_API_URL=http://localhost:3001/api
REACT_APP_ENV=production
EOF

echo "✅ Arquivo .env criado!"
echo ""
echo "📝 Agora configure as variáveis do RDS:"
echo "   nano .env"
echo ""
echo "🔧 Exemplo de configuração:"
echo "   RDS_HOST=personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com"
echo "   RDS_USERNAME=root"
echo "   RDS_PASSWORD=rootpassword"
echo "   RDS_DATABASE=personal_trainer_db"
echo ""
echo "🚀 Após configurar, execute:"
echo "   ./setup-env.sh" 