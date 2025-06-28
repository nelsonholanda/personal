# NH-Personal - Sistema de Gestão para Personal Trainers

Um sistema completo e moderno para personal trainers gerenciarem seus clientes, pagamentos, treinos e progresso de forma eficiente e intuitiva.

## 🚀 Funcionalidades Principais

### 👥 Gestão de Clientes
- **Cadastro e gerenciamento completo de clientes**
- **Controle de status** (Ativo, Inativo, Suspenso, Concluído)
- **Configuração de aulas semanais** por cliente
- **Histórico de treinos e progresso**
- **Checkboxes para ações em lote** - facilita a gestão de múltiplos clientes
- **Filtros avançados** por status, nome, email
- **Busca inteligente** em tempo real
- **Anotações e observações personalizadas**

### 💰 Gestão Financeira
- **Controle completo de pagamentos**
- **Múltiplas formas de pagamento** (PIX, Cartão, Dinheiro, Transferência)
- **Planos de pagamento pré-definidos** e personalizados
- **Sistema de parcelas** automático
- **Status de pagamentos** (Pendente, Pago, Em Atraso, Cancelado)
- **Relatórios financeiros** detalhados
- **Marcação rápida de pagamentos** com checkboxes
- **Histórico completo** de transações

### 🔐 Gerenciamento de Senhas Seguro
- **Criptografia avançada** com bcrypt (12 rounds de salt)
- **Histórico de senhas** (prevenção de reutilização)
- **Validação robusta** de senhas (mínimo 8 caracteres, maiúsculas, minúsculas, números, caracteres especiais)
- **Reset de senha** via email com tokens seguros
- **Geração de senhas seguras** automática
- **Forçar mudança de senha** para usuários
- **Controle de expiração** de tokens de reset

### 🔒 Segurança Avançada
- **AWS Secrets Manager** para armazenamento seguro de credenciais
- **AWS KMS** para criptografia adicional
- **Rate limiting** para proteção contra ataques
- **Helmet.js** para headers de segurança
- **CORS** configurado adequadamente
- **Validação de entrada** rigorosa

### 👨‍💼 Usuário Administrador
- **Usuário admin criado**: `nholanda`
- **Senha inicial**: `rdms95gn`
- **Permissões completas** de gerenciamento
- **Controle total** sobre usuários e senhas

### 📊 Dashboard e Relatórios
- **Visão geral financeira** em tempo real
- **Estatísticas de clientes** ativos
- **Gráficos de receita** e pagamentos pendentes
- **Relatórios por período** personalizáveis
- **Exportação de dados** para análise

### 🏋️ Gestão de Treinos
- **Criação de planos de treino** personalizados
- **Biblioteca de exercícios** com vídeos e imagens
- **Acompanhamento de progresso** dos clientes
- **Agendamento de sessões** e consultas
- **Histórico de treinos** realizados

### 📅 Agendamentos
- **Sistema de agendamento** intuitivo
- **Lembretes automáticos** para clientes
- **Controle de disponibilidade** do personal
- **Sessões online** e presenciais

## 🏗️ Arquitetura

### Backend
- **Node.js** com TypeScript
- **Express.js** para API REST
- **Prisma ORM** para banco de dados
- **MySQL 8.0** via RDS AWS
- **JWT** para autenticação
- **AWS SDK** para integração com serviços AWS
- **Rate limiting** e segurança
- **Validação de dados** robusta

### Frontend
- **React 18** com TypeScript
- **React Router** para navegação
- **React Query** para gerenciamento de estado
- **Tailwind CSS** para estilização
- **Lucide React** para ícones
- **React Hot Toast** para notificações
- **Interface responsiva** e moderna

### Infraestrutura
- **Docker** para containerização
- **Docker Compose** para orquestração
- **Nginx** como reverse proxy
- **RDS AWS** para banco de dados
- **AWS Secrets Manager** para credenciais
- **AWS KMS** para criptografia
- **Deploy automatizado** com scripts

## 🛠️ Tecnologias Utilizadas

### Backend
- Node.js 18+
- Express.js
- TypeScript
- Prisma ORM
- MySQL 8.0 (RDS AWS)
- JWT
- bcryptjs
- AWS SDK
- cors
- helmet
- express-rate-limit
- compression

### Frontend
- React 18
- TypeScript
- React Router DOM
- React Query
- Tailwind CSS
- Lucide React
- React Hot Toast
- Axios

### DevOps
- Docker
- Docker Compose
- Nginx
- Shell Scripts
- AWS RDS
- AWS Secrets Manager
- AWS KMS
- GitHub Actions (opcional)

## 📦 Instalação e Configuração

### Pré-requisitos
- Docker e Docker Compose
- Node.js 18+ (para desenvolvimento local)
- Git
- Conta AWS (para RDS e Secrets Manager)

### 1. Clone o repositório
```bash
git clone <repository-url>
cd nh-personal
```

### 2. Configure as variáveis de ambiente
```bash
cp env.example .env
# Edite o arquivo .env com suas configurações
```

### 3. Configure AWS RDS e Secrets Manager

O sistema está configurado para usar:
- **RDS Host**: `personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com`
- **Secret Name**: `rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811`

Para configurar AWS Secrets Manager:

1. Crie um secret para JWT com o nome `nh-personal/jwt`:
```json
{
  "accessTokenSecret": "your-access-token-secret",
  "refreshTokenSecret": "your-refresh-token-secret"
}
```

2. Configure as credenciais AWS no arquivo `.env`:
```env
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
```

### 4. Inicialize o banco de dados
```bash
# Execute o script de inicialização do banco
./init-database.sh
```

### 5. Inicie o ambiente de desenvolvimento
```bash
# Usando Docker (recomendado)
./start.sh

# Ou manualmente
docker-compose up -d
```

### 6. Acesse a aplicação
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:3001
- **Health Check**: http://localhost:3001/health

## 🚀 Deploy em Produção

### Opção 1: Deploy Automatizado (Recomendado)

Use o script de User Data para instâncias EC2:

```bash
# Execute o script de instalação
./install-dependencies.sh

# Ou use no User Data da instância EC2
./aws-userdata.sh
```

### Opção 2: Deploy Manual

1. **Configure o servidor**:
```bash
# Execute o script de instalação
sudo ./install-dependencies.sh
```

2. **Configure o banco de dados**:
```bash
# Inicialize o banco RDS
sudo ./init-database.sh
```

3. **Configure as variáveis de ambiente**:
```bash
# Edite o arquivo de configuração
sudo nano /opt/nh-personal/.env
```

4. **Inicie os serviços**:
```bash
# Inicie os serviços systemd
sudo systemctl start nh-personal-backend nh-personal-frontend
sudo systemctl enable nh-personal-backend nh-personal-frontend
```

### 3. Configure SSL (Opcional)
```bash
# Instale Certbot
sudo apt-get install certbot python3-certbot-nginx

# Configure SSL
sudo certbot --nginx -d seu-dominio.com
```

## 🔧 Configuração do RDS

### Configurações Atuais
- **Host**: `personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com`
- **Porta**: `3306`
- **Usuário**: `root`
- **Senha**: `rootpassword`
- **Banco**: `personal_trainer_db`
- **Região**: `us-east-2`

### Teste de Conexão
```bash
# Teste a conexão com o RDS
mysql -h personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com -u root -prootpassword -e "SELECT 1;"
```

### Migrações do Prisma
```bash
# Execute as migrações
cd backend
npx prisma migrate deploy
npx prisma generate
```

## 📊 Monitoramento

### Scripts de Monitoramento
- **Monitor automático**: `/opt/nh-personal/monitor.sh`
- **Logs**: `/opt/nh-personal/logs/`
- **Health Check**: `http://localhost:3001/health`

### Comandos Úteis
```bash
# Verificar status dos serviços
sudo systemctl status nh-personal-backend nh-personal-frontend nginx

# Ver logs
sudo journalctl -u nh-personal-backend -f
sudo journalctl -u nh-personal-frontend -f

# Reiniciar serviços
sudo systemctl restart nh-personal-backend nh-personal-frontend

# Testar conexão RDS
mysql -h personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com -u root -p
```

## 🔐 Segurança

### Configurações de Segurança
- **Senhas criptografadas** com bcrypt (12 rounds)
- **JWT tokens** com expiração configurável
- **Rate limiting** ativo
- **Headers de segurança** com Helmet.js
- **CORS** configurado adequadamente
- **AWS Secrets Manager** para credenciais sensíveis

### Usuários Padrão
- **Email**: `admin@nhpersonal.com`
- **Email**: `nholanda@nhpersonal.com`
- **Senha**: `rdms95gn`
- **Role**: `admin`

## 📚 API Documentation

### Endpoints Principais

#### Autenticação
- `POST /api/auth/login` - Login
- `POST /api/auth/register` - Registro
- `POST /api/auth/refresh` - Renovar token

#### Gestão de Clientes
- `GET /api/client-management` - Listar clientes
- `POST /api/client-management` - Adicionar cliente
- `PUT /api/client-management/:id` - Atualizar cliente
- `DELETE /api/client-management/:id` - Remover cliente

#### Pagamentos
- `GET /api/payments` - Listar pagamentos
- `POST /api/payments` - Criar pagamento
- `PUT /api/payments/:id/status` - Atualizar status
- `GET /api/payments/methods` - Métodos de pagamento
- `GET /api/payments/plans` - Planos de pagamento

#### Gestão de Senhas
- `POST /api/passwords/change` - Alterar senha
- `POST /api/passwords/reset-request` - Solicitar reset
- `POST /api/passwords/reset` - Resetar senha
- `GET /api/passwords/history` - Histórico de senhas
- `POST /api/passwords/admin-reset` - Reset admin

### Exemplo de Uso
```bash
# Login
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"nholanda@nhpersonal.com","password":"rdms95gn"}'

# Listar clientes (com token)
curl -X GET http://localhost:3001/api/client-management \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🐛 Troubleshooting

### Problemas Comuns

#### 1. Erro de Conexão com RDS
```bash
# Verifique a conectividade
telnet personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com 3306

# Teste com MySQL client
mysql -h personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com -u root -p
```

#### 2. Serviços Não Iniciam
```bash
# Verifique os logs
sudo journalctl -u nh-personal-backend -n 50
sudo journalctl -u nh-personal-frontend -n 50

# Verifique as permissões
sudo chown -R root:root /opt/nh-personal
sudo chmod 600 /opt/nh-personal/.env
```

#### 3. Erro de Migração Prisma
```bash
# Execute as migrações manualmente
cd /opt/nh-personal/backend
export DATABASE_URL="mysql://root:rootpassword@personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com:3306/personal_trainer_db"
npx prisma migrate deploy
npx prisma generate
```

## 📞 Suporte

Para suporte técnico:
- **Email**: suporte@nhpersonal.com
- **Documentação**: Consulte `API_DOCUMENTATION.md`
- **Scripts**: Consulte `SCRIPTS_README.md`

## 📄 Licença

Este projeto é privado e de uso exclusivo para NH-Personal.

---

**Desenvolvido com ❤️ para NH-Personal** 