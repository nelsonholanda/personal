#!/bin/bash

echo "🚀 Deploying Personal Trainer Application to Production..."
echo "=========================================================="

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

# Verificar se o arquivo .env existe
if [ ! -f .env ]; then
    echo "❌ Arquivo .env não encontrado. Copie o arquivo env.example para .env e configure as variáveis."
    exit 1
fi

# Carregar variáveis de ambiente
source .env

# Verificar variáveis obrigatórias
if [ -z "$JWT_SECRET" ] || [ "$JWT_SECRET" = "your-super-secret-jwt-key-change-in-production" ]; then
    echo "❌ JWT_SECRET não está configurado corretamente no arquivo .env"
    exit 1
fi

if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL não está configurado no arquivo .env"
    exit 1
fi

# Backup do banco de dados (se existir)
if docker-compose ps mysql | grep -q "Up"; then
    echo "💾 Criando backup do banco de dados..."
    docker-compose exec mysql mysqldump -u root -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE > backup_$(date +%Y%m%d_%H%M%S).sql
    echo "✅ Backup criado com sucesso!"
fi

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down

# Remover imagens antigas
echo "🗑️  Removendo imagens antigas..."
docker system prune -f

# Construir e iniciar containers de produção
echo "🔨 Construindo e iniciando containers de produção..."
docker-compose -f docker-compose.prod.yml up --build -d

# Aguardar serviços ficarem prontos
echo "⏳ Aguardando serviços ficarem prontos..."
sleep 45

# Verificar status dos containers
echo "📊 Status dos containers:"
docker-compose -f docker-compose.prod.yml ps

# Verificar health checks
echo "🏥 Verificando health checks..."
sleep 10

# Testar endpoints
echo "🧪 Testando endpoints..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ Health check: OK"
else
    echo "❌ Health check: FAILED"
fi

if curl -f http://localhost/api/auth/login > /dev/null 2>&1; then
    echo "✅ API endpoint: OK"
else
    echo "❌ API endpoint: FAILED"
fi

# Verificar logs
echo "📋 Logs dos serviços:"
echo "======================"

echo "🐳 MySQL:"
docker-compose -f docker-compose.prod.yml logs mysql --tail=3

echo "🔧 Backend:"
docker-compose -f docker-compose.prod.yml logs backend --tail=3

echo "⚛️  Frontend:"
docker-compose -f docker-compose.prod.yml logs frontend --tail=3

echo "🌐 Nginx:"
docker-compose -f docker-compose.prod.yml logs nginx --tail=3

echo "=========================================================="
echo "🎉 Deploy concluído com sucesso!"
echo ""
echo "📱 Aplicação disponível em:"
echo "   • Frontend: http://localhost"
echo "   • Backend API: http://localhost/api"
echo "   • Health Check: http://localhost/health"
echo ""
echo "🔧 Comandos úteis:"
echo "   • Ver logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "   • Parar: docker-compose -f docker-compose.prod.yml down"
echo "   • Reiniciar: docker-compose -f docker-compose.prod.yml restart"
echo "   • Status: docker-compose -f docker-compose.prod.yml ps"
echo ""
echo "📚 Para mais informações, consulte o README.md"
echo "==========================================================" 