#!/bin/bash

# Script de Deploy para Amazon Linux 2023 - NH Personal Trainer
# Versão: 2.1.0 - Amazon Linux 2023 (Sem dependência do curl)

set -e  # Para o script se houver erro

echo "🚀 Iniciando deploy para Amazon Linux 2023 (versão sem curl)..."

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

# Verificar se estamos rodando como root ou com sudo
if [ "$EUID" -eq 0 ]; then
    error "Não execute este script como root. Use sudo quando necessário."
fi

log "📋 Verificando sistema..."

# Verificar se é Amazon Linux 2023
if ! grep -q "Amazon Linux release 2023" /etc/os-release; then
    warning "Este script foi otimizado para Amazon Linux 2023. Outras distribuições podem não funcionar corretamente."
fi

# Atualizar sistema
log "🔄 Atualizando sistema..."
sudo dnf update -y

# Instalar dependências básicas (sem curl)
log "📦 Instalando dependências básicas..."
sudo dnf install -y git wget unzip jq

success "Dependências básicas instaladas"

# Instalar Docker
log "🐳 Instalando Docker..."
sudo dnf install -y docker

# Iniciar e habilitar Docker
sudo systemctl start docker
sudo systemctl enable docker

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

success "Docker instalado e configurado"

# Instalar Docker Compose usando wget
log "📦 Instalando Docker Compose..."
DOCKER_COMPOSE_VERSION=$(wget -qO- https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
sudo wget -O /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
sudo chmod +x /usr/local/bin/docker-compose

# Criar link simbólico
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

success "Docker Compose instalado"

# Configurar firewall (se estiver usando firewalld)
log "🔒 Configurando firewall..."
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=80/tcp
    sudo firewall-cmd --permanent --add-port=443/tcp
    sudo firewall-cmd --permanent --add-port=3001/tcp
    sudo firewall-cmd --reload
    success "Firewall configurado"
else
    warning "Firewalld não encontrado. Configure o firewall manualmente."
fi

# Clonar repositório
log "📥 Clonando repositório..."
if [ ! -d "projeto-personal" ]; then
    git clone https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git projeto-personal
fi
cd projeto-personal

# Configurar variáveis de ambiente
log "⚙️ Configurando variáveis de ambiente..."

# Backend .env
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
EOF

# Frontend .env
cat > frontend/.env <<EOF
REACT_APP_API_URL=http://localhost:3001/api
NODE_ENV=production
EOF

success "Variáveis de ambiente configuradas"

# Recarregar grupos do usuário
log "🔄 Recarregando grupos do usuário..."
newgrp docker

# Construir e iniciar containers
log "🐳 Construindo e iniciando containers..."
sudo docker-compose -f docker-compose.prod.yml up --build -d

success "Containers iniciados"

# Aguardar serviços estarem prontos
log "⏳ Aguardando serviços estarem prontos..."
sleep 30

# Executar migrações
log "🗄️ Executando migrações do banco..."
sudo docker-compose -f docker-compose.prod.yml exec -T backend npx prisma migrate deploy

success "Migrações executadas"

# Criar usuário administrador
log "👤 Criando usuário administrador..."
sudo docker-compose -f docker-compose.prod.yml exec -T backend node scripts/create-admin-user.js

success "Usuário administrador criado"

# Verificar status dos serviços
log "📊 Verificando status dos serviços..."
sudo docker-compose -f docker-compose.prod.yml ps

# Verificar se todos os serviços estão rodando
if sudo docker-compose -f docker-compose.prod.yml ps | grep -q "Exit"; then
    warning "Alguns serviços não iniciaram corretamente"
    sudo docker-compose -f docker-compose.prod.yml logs --tail=50
else
    success "Todos os serviços estão rodando"
fi

# Configurar logs
log "📝 Configurando logs..."
sudo mkdir -p /var/log/nh-personal
sudo chown $USER:$USER /var/log/nh-personal

# Criar script de monitoramento
log "📈 Configurando monitoramento..."
cat > monitor.sh << 'EOF'
#!/bin/bash
# Script de monitoramento para NH Personal Trainer - Amazon Linux 2023

LOG_FILE="/var/log/nh-personal/monitor.log"

while true; do
    echo "$(date): Verificando serviços..." >> $LOG_FILE
    
    # Verificar se os containers estão rodando
    if ! sudo docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
        echo "$(date): ERRO - Alguns serviços pararam!" >> $LOG_FILE
        # Aqui você pode adicionar notificação por email/SMS
    fi
    
    # Verificar uso de memória
    MEMORY_USAGE=$(sudo docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}" | grep -E "(frontend|backend|mysql)" | awk '{sum+=$2} END {print sum}')
    echo "$(date): Uso de memória: $MEMORY_USAGE" >> $LOG_FILE
    
    sleep 300  # Verificar a cada 5 minutos
done
EOF

chmod +x monitor.sh

# Criar script de backup
log "📋 Configurando backup automático..."
cat > backup.sh << 'EOF'
#!/bin/bash
# Script de backup para NH Personal Trainer - Amazon Linux 2023

BACKUP_DIR="/var/log/nh-personal/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup do banco de dados (se estiver usando MySQL local)
if sudo docker-compose -f docker-compose.prod.yml ps mysql | grep -q "Up"; then
    sudo docker-compose -f docker-compose.prod.yml exec mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD:-password} personal_trainer_db > $BACKUP_DIR/db_backup_$DATE.sql
fi

# Backup dos logs
tar -czf $BACKUP_DIR/logs_backup_$DATE.tar.gz /var/log/nh-personal/

# Manter apenas os últimos 7 backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup criado: $BACKUP_DIR"
EOF

chmod +x backup.sh

# Configurar backup automático no crontab
(crontab -l 2>/dev/null; echo "0 2 * * * $(pwd)/backup.sh") | crontab -

success "Backup automático configurado"

# Configurar limpeza automática de logs do Docker
log "🧹 Configurando limpeza automática..."
sudo tee /etc/cron.daily/docker-cleanup << 'EOF'
#!/bin/bash
# Limpeza automática de containers e imagens Docker

# Remover containers parados
sudo docker container prune -f

# Remover imagens não utilizadas
sudo docker image prune -f

# Remover volumes não utilizados
sudo docker volume prune -f

# Remover redes não utilizadas
sudo docker network prune -f
EOF

sudo chmod +x /etc/cron.daily/docker-cleanup

success "Limpeza automática configurada"

# Obter IP público da instância usando wget
PUBLIC_IP=$(wget -qO- http://169.254.169.254/latest/meta-data/public-ipv4)

echo ""
echo "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
echo "=================================="
echo "🌐 URLs da aplicação:"
echo "   Frontend: http://$PUBLIC_IP:3000"
echo "   Backend:  http://$PUBLIC_IP:3001"
echo "   Health Check: http://$PUBLIC_IP:3001/health"
echo ""
echo "👤 Credenciais de Administrador:"
echo "   Email: nholanda@nhpersonal.com"
echo "   Senha: P10r1988!"
echo ""
echo "🔧 Comandos úteis:"
echo "   Ver logs: sudo docker-compose -f docker-compose.prod.yml logs -f"
echo "   Reiniciar: sudo docker-compose -f docker-compose.prod.yml restart"
echo "   Parar: sudo docker-compose -f docker-compose.prod.yml down"
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

success "Deploy finalizado com sucesso!" 