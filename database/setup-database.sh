#!/bin/bash

# NH Gestão de Alunos - Script de Configuração do Banco de Dados
# Este script configura o banco de dados MySQL e executa as migrações do Prisma

echo "🚀 Configurando banco de dados NH Gestão de Alunos..."
echo "=================================================="

# Configurações do banco
DB_HOST="personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com"
DB_PORT="3306"
DB_USER="admin"
DB_PASS="Rdms95gn!"
DB_NAME="personal_trainer_db"

# Verificar se o MySQL está acessível
echo "🔍 Verificando conexão com o banco de dados..."
if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ Erro: Não foi possível conectar ao banco de dados MySQL"
    echo "   Host: $DB_HOST"
    echo "   Port: $DB_PORT"
    echo "   User: $DB_USER"
    exit 1
fi

echo "✅ Conexão com o banco estabelecida!"

# Executar script SQL de inicialização
echo "📊 Criando tabelas e estrutura do banco..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" < init.sql

if [ $? -eq 0 ]; then
    echo "✅ Estrutura do banco criada com sucesso!"
else
    echo "❌ Erro ao criar estrutura do banco"
    exit 1
fi

# Verificar se as tabelas foram criadas
echo "🔍 Verificando tabelas criadas..."
TABLES=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "SHOW TABLES;" | wc -l)
echo "📋 Total de tabelas encontradas: $((TABLES - 1))"

# Listar tabelas criadas
echo "📋 Tabelas criadas:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "SHOW TABLES;" | tail -n +2

# Verificar dados iniciais
echo "🔍 Verificando dados iniciais..."
echo "   Métodos de pagamento:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "SELECT COUNT(*) as total FROM payment_methods;"

echo "   Planos de pagamento:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "SELECT COUNT(*) as total FROM payment_plans;"

echo "   Exercícios:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "SELECT COUNT(*) as total FROM exercises;"

echo ""
echo "🎉 Configuração do banco de dados concluída!"
echo "=========================================="
echo "📊 Banco: $DB_NAME"
echo "🌐 Host: $DB_HOST"
echo "👤 Usuário: $DB_USER"
echo ""
echo "💡 Próximos passos:"
echo "   1. Execute o script de criação do usuário admin:"
echo "      docker exec -it personal_trainer_backend node scripts/create-admin-user.js"
echo ""
echo "   2. Acesse o sistema em: http://seu-ip:3000"
echo "   3. Login: nholanda@nhpersonal.com"
echo "   4. Senha: P10r1988!"
echo "" 