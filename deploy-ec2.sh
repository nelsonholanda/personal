#!/bin/bash

set -e  # Exit on any error

echo "🚀 Iniciando deploy do NH-Personal na EC2 (Amazon Linux 2023)..."

# 1. Atualizar sistema e instalar dependências
echo "📦 Atualizando sistema e instalando dependências..."
sudo dnf update -y
sudo dnf install -y git curl wget

# 2. Instalar Docker
echo "🐳 Instalando Docker..."
sudo dnf install -y docker

# Iniciar e habilitar o serviço Docker
sudo systemctl start docker
sudo systemctl enable docker

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# 3. Instalar Docker Compose
echo "📦 Instalando Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Criar link simbólico para docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# 4. Clonar o repositório (ajuste a URL se necessário)
echo "📥 Clonando repositório..."
if [ ! -d "projeto-personal" ]; then
  git clone https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git projeto-personal
fi
cd projeto-personal

# 5. Gerar arquivo .env de produção para o backend
echo "⚙️ Configurando variáveis de ambiente..."
cat > backend/.env <<EOF
ENCRYPTION_KEY=nh-personal-encryption-key-2024
DB_HOST=personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com
DB_PORT=3306
DB_USERNAME=admin
DB_PASSWORD_ENCRYPTED=f0ab35538ff8e4e7825363b2b5a348dc:654375d1c2216dc33d8c917db2ddc501
DB_NAME=personal_trainer_db
NODE_ENV=production
PORT=3001
JWT_ACCESS_TOKEN_SECRET=nh-personal-access-token-secret-2024
JWT_REFRESH_TOKEN_SECRET=nh-personal-refresh-token-secret-2024
# SMTP_HOST=smtp.gmail.com
# SMTP_PORT=587
# SMTP_USER=seu-email@gmail.com
# SMTP_PASS=sua-senha-app
# SMTP_FROM=noreply@nhpersonal.com
EOF

# 6. Gerar arquivo .env de produção para o frontend
cat > frontend/.env <<EOF
REACT_APP_API_URL=http://localhost:3001/api
NODE_ENV=production
EOF

# 7. Recarregar grupos do usuário (para aplicar a adição ao grupo docker)
echo "🔄 Recarregando grupos do usuário..."
newgrp docker

# 8. Build e up dos containers
echo "🐳 Construindo e iniciando containers..."
sudo docker-compose -f docker-compose.prod.yml up --build -d

# 9. Aguardar o backend estar pronto
echo "⏳ Aguardando o backend estar pronto..."
sleep 30

# 10. Executar migrações e criar usuário admin
echo "🗄️ Executando migrações do banco..."
sudo docker-compose -f docker-compose.prod.yml exec -T backend npx prisma migrate deploy

echo "👤 Criando usuário administrador..."
sudo docker-compose -f docker-compose.prod.yml exec -T backend node scripts/create-admin-user.js

# 11. Verificar status dos containers
echo "📊 Status dos containers:"
sudo docker-compose -f docker-compose.prod.yml ps

# 12. Logs iniciais
echo "📋 Logs recentes:"
sudo docker-compose -f docker-compose.prod.yml logs --tail=20

echo ""
echo "🎉 Deploy finalizado com sucesso!"
echo "=================================="
echo "🌐 API: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3001"
echo "🔍 Health Check: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3001/health"
echo ""
echo "👤 Credenciais de Administrador:"
echo "   Email: nholanda@nhpersonal.com"
echo "   Senha: P10r1988!"
echo ""
echo "📋 Comandos úteis:"
echo "   Logs: sudo docker-compose -f docker-compose.prod.yml logs -f"
echo "   Parar: sudo docker-compose -f docker-compose.prod.yml down"
echo "   Reiniciar: sudo docker-compose -f docker-compose.prod.yml restart"
echo ""
echo "✅ Sistema pronto para uso!" 