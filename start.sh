#!/bin/bash

echo "🚀 Iniciando Personal Trainer Application..."
echo "=============================================="

# Verificar se o Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não está instalado. Por favor, instale o Docker primeiro."
    exit 1
fi

# Verificar se o Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose não está instalado. Por favor, instale o Docker Compose primeiro."
    exit 1
fi

# Criar arquivo .env se não existir
if [ ! -f .env ]; then
    echo "📝 Criando arquivo .env..."
    cat > .env << EOF
# Database Configuration
DATABASE_URL=mysql://app_user:app_password@mysql:3306/personal_trainer_db

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production

# API Configuration
PORT=3001
NODE_ENV=development
FRONTEND_URL=http://localhost:3000

# Frontend Configuration
REACT_APP_API_URL=http://localhost:3001
REACT_APP_ENV=development
EOF
    echo "✅ Arquivo .env criado com sucesso!"
fi

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down

# Remover volumes antigos (opcional)
read -p "🗑️  Deseja remover volumes antigos? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removendo volumes antigos..."
    docker-compose down -v
fi

# Construir e iniciar containers
echo "🔨 Construindo e iniciando containers..."
docker-compose up --build -d

# Aguardar serviços ficarem prontos
echo "⏳ Aguardando serviços ficarem prontos..."
sleep 30

# Verificar status dos containers
echo "📊 Status dos containers:"
docker-compose ps

# Verificar logs
echo "📋 Logs dos serviços:"
echo "======================"

echo "🐳 MySQL:"
docker-compose logs mysql --tail=5

echo "🔧 Backend:"
docker-compose logs backend --tail=5

echo "⚛️  Frontend:"
docker-compose logs frontend --tail=5

echo "🌐 Nginx:"
docker-compose logs nginx --tail=5

echo "=============================================="
echo "🎉 Aplicação iniciada com sucesso!"
echo ""
echo "📱 Acesse a aplicação em:"
echo "   • Frontend: http://localhost:3000"
echo "   • Backend API: http://localhost:3001"
echo "   • Nginx: http://localhost:80"
echo "   • Health Check: http://localhost:3001/health"
echo ""
echo "🔧 Comandos úteis:"
echo "   • Ver logs: docker-compose logs -f"
echo "   • Parar: docker-compose down"
echo "   • Reiniciar: docker-compose restart"
echo "   • Rebuild: docker-compose up --build"
echo ""
echo "📚 Para mais informações, consulte o README.md"
echo "==============================================" 