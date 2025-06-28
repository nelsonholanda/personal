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

# Iniciar os containers
echo "🚀 Iniciando containers..."
docker-compose up --build -d

# Aguardar um pouco para os serviços inicializarem
echo "⏳ Aguardando inicialização dos serviços..."
sleep 15

# Verificar status dos containers
echo "📊 Status dos containers:"
docker-compose ps

# Verificar se todos os containers estão rodando
echo "🔍 Verificando logs dos serviços..."

# Verificar logs do MySQL
echo "📋 Logs do MySQL:"
docker-compose logs mysql --tail=3

# Verificar logs do Backend
echo "📋 Logs do Backend:"
docker-compose logs backend --tail=3

# Verificar logs do Frontend
echo "📋 Logs do Frontend:"
docker-compose logs frontend --tail=3

# Verificar logs do Nginx
echo "📋 Logs do Nginx:"
docker-compose logs nginx --tail=3

# Testar endpoints
echo "🏥 Testando endpoints..."

# Testar health check do backend
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

# Testar nginx
if curl -f http://localhost > /dev/null 2>&1; then
    echo "✅ Nginx: OK"
else
    echo "❌ Nginx: FALHOU"
fi

echo ""
echo "🎉 DEPLOY CONCLUÍDO!"
echo ""
echo "📱 URLs da aplicação:"
echo "   • Frontend: http://localhost:3000"
echo "   • Backend:  http://localhost:3001"
echo "   • Nginx:    http://localhost"
echo ""
echo "🔧 Comandos úteis:"
echo "   • Ver logs: docker-compose logs -f"
echo "   • Parar: docker-compose down"
echo "   • Reiniciar: docker-compose restart"
echo "   • Status: docker-compose ps"
echo ""
echo "📚 Para mais informações, consulte o README.md"
echo "==========================================================" 