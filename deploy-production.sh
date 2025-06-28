#!/bin/bash

# Script de Deploy para Produção - NH Personal Trainer
# Versão: 1.0.0

set -e  # Para o script se houver erro

echo "🚀 Iniciando deploy para produção..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    error "Execute este script no diretório raiz do projeto"
fi

# Verificar se o .env existe
if [ ! -f ".env" ]; then
    error "Arquivo .env não encontrado. Copie o env.example e configure as variáveis"
fi

log "📋 Verificando dependências..."

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    error "Docker não está instalado"
fi

# Verificar se Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose não está instalado"
fi

success "Dependências verificadas"

log "🔧 Configurando ambiente de produção..."

# Parar containers existentes
log "🛑 Parando containers existentes..."
docker-compose down --remove-orphans

# Limpar imagens antigas (opcional)
read -p "Deseja limpar imagens Docker antigas? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "🧹 Limpando imagens antigas..."
    docker system prune -f
fi

log "🏗️ Construindo imagens para produção..."

# Construir imagens com tag de produção
docker-compose -f docker-compose.prod.yml build --no-cache

success "Imagens construídas"

log "🗄️ Iniciando banco de dados..."

# Iniciar apenas o banco de dados primeiro
docker-compose -f docker-compose.prod.yml up -d mysql

# Aguardar o banco estar pronto
log "⏳ Aguardando banco de dados estar pronto..."
sleep 30

# Verificar se o banco está rodando
if ! docker-compose -f docker-compose.prod.yml ps mysql | grep -q "Up"; then
    error "Banco de dados não iniciou corretamente"
fi

success "Banco de dados iniciado"

log "🔄 Executando migrações..."

# Executar migrações do Prisma
docker-compose -f docker-compose.prod.yml run --rm backend npx prisma migrate deploy

success "Migrações executadas"

log "🌱 Populando dados iniciais..."

# Executar seed do banco (se existir)
if [ -f "database/seed.sql" ]; then
    docker-compose -f docker-compose.prod.yml exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD:-password} personal_trainer_db < database/seed.sql
fi

log "🚀 Iniciando aplicação..."

# Iniciar todos os serviços
docker-compose -f docker-compose.prod.yml up -d

success "Aplicação iniciada"

log "⏳ Aguardando serviços estarem prontos..."
sleep 10

# Verificar status dos serviços
log "📊 Status dos serviços:"
docker-compose -f docker-compose.prod.yml ps

# Verificar se todos os serviços estão rodando
if docker-compose -f docker-compose.prod.yml ps | grep -q "Exit"; then
    warning "Alguns serviços não iniciaram corretamente"
    docker-compose -f docker-compose.prod.yml logs --tail=50
else
    success "Todos os serviços estão rodando"
fi

log "🔍 Verificando endpoints..."

# Verificar se o backend está respondendo
if curl -f http://localhost:3001/health > /dev/null 2>&1; then
    success "Backend está respondendo"
else
    warning "Backend não está respondendo no endpoint /health"
fi

# Verificar se o frontend está respondendo
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    success "Frontend está respondendo"
else
    warning "Frontend não está respondendo"
fi

log "📝 Configurando logs..."

# Configurar rotação de logs
if [ ! -d "/var/log/nh-personal" ]; then
    sudo mkdir -p /var/log/nh-personal
    sudo chown $USER:$USER /var/log/nh-personal
fi

success "Logs configurados"

log "🔒 Configurando firewall..."

# Configurar firewall (se estiver usando UFW)
if command -v ufw &> /dev/null; then
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 3001/tcp
    warning "Firewall configurado - verifique se as portas estão corretas"
fi

log "📈 Configurando monitoramento..."

# Criar script de monitoramento
cat > monitor.sh << 'EOF'
#!/bin/bash
# Script de monitoramento para NH Personal Trainer

while true; do
    echo "$(date): Verificando serviços..."
    
    # Verificar se os containers estão rodando
    if ! docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
        echo "$(date): ERRO - Alguns serviços pararam!"
        # Aqui você pode adicionar notificação por email/SMS
    fi
    
    # Verificar uso de memória
    MEMORY_USAGE=$(docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}" | grep -E "(frontend|backend|mysql)" | awk '{sum+=$2} END {print sum}')
    echo "$(date): Uso de memória: $MEMORY_USAGE"
    
    sleep 300  # Verificar a cada 5 minutos
done
EOF

chmod +x monitor.sh

success "Monitoramento configurado"

log "📋 Criando backup automático..."

# Criar script de backup
cat > backup.sh << 'EOF'
#!/bin/bash
# Script de backup para NH Personal Trainer

BACKUP_DIR="/backup/nh-personal"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup do banco de dados
docker-compose -f docker-compose.prod.yml exec mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD:-password} personal_trainer_db > $BACKUP_DIR/db_backup_$DATE.sql

# Backup dos logs
tar -czf $BACKUP_DIR/logs_backup_$DATE.tar.gz /var/log/nh-personal/

# Manter apenas os últimos 7 backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup criado: $BACKUP_DIR"
EOF

chmod +x backup.sh

# Adicionar ao crontab para backup diário
(crontab -l 2>/dev/null; echo "0 2 * * * $(pwd)/backup.sh") | crontab -

success "Backup automático configurado"

echo ""
echo "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
echo ""
echo "📱 URLs da aplicação:"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:3001"
echo "   API Docs: http://localhost:3001/api-docs"
echo ""
echo "🔧 Comandos úteis:"
echo "   Ver logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "   Reiniciar: docker-compose -f docker-compose.prod.yml restart"
echo "   Parar: docker-compose -f docker-compose.prod.yml down"
echo "   Monitorar: ./monitor.sh"
echo "   Backup manual: ./backup.sh"
echo ""
echo "⚠️  PRÓXIMOS PASSOS:"
echo "   1. Configure um domínio e SSL"
echo "   2. Configure backup externo"
echo "   3. Configure monitoramento externo"
echo "   4. Configure alertas por email"
echo "   5. Teste todos os recursos da aplicação"
echo ""
echo "📞 Suporte: Entre em contato se precisar de ajuda"
echo ""

# Adicionar o comando para iniciar uma sessão SSM
echo "📋 Adicionando comando para iniciar uma sessão SSM..."
echo "aws ssm start-session --target i-07aeed4a8c16b0b7e"
echo ""

echo "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
echo ""
echo "📱 URLs da aplicação:"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:3001"
echo "   API Docs: http://localhost:3001/api-docs"
echo ""
echo "🔧 Comandos úteis:"
echo "   Ver logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "   Reiniciar: docker-compose -f docker-compose.prod.yml restart"
echo "   Parar: docker-compose -f docker-compose.prod.yml down"
echo "   Monitorar: ./monitor.sh"
echo "   Backup manual: ./backup.sh"
echo ""
echo "⚠️  PRÓXIMOS PASSOS:"
echo "   1. Configure um domínio e SSL"
echo "   2. Configure backup externo"
echo "   3. Configure monitoramento externo"
echo "   4. Configure alertas por email"
echo "   5. Teste todos os recursos da aplicação"
echo ""
echo "📞 Suporte: Entre em contato se precisar de ajuda"
echo ""

chmod +x deploy-ec2.sh
./deploy-ec2.sh 