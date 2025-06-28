# NH Personal Trainer

Sistema completo de gerenciamento para personal trainers, incluindo controle de clientes, pagamentos e treinos.

## 🚀 Deploy Rápido

### Pré-requisitos
- Docker e Docker Compose instalados
- Acesso ao Amazon RDS MySQL
- Configuração do AWS Secrets Manager (opcional)

### 1. Deploy Automático (Recomendado)

```bash
# Executar deploy simplificado
./deploy-simple.sh
```

Este script irá:
- Criar arquivo `.env` se não existir
- Verificar configurações
- Limpar containers órfãos
- Construir e iniciar os serviços

### 2. Deploy Manual

#### Configurar Variáveis de Ambiente

```bash
# Criar arquivo .env
./create-env.sh

# Editar configurações
nano .env
```

Configure as variáveis do RDS:
```env
# Opção A: AWS Secrets Manager (recomendado)
AWS_SECRET_NAME=rds!db-da675fb5-6491-4bf4-981a-2fa9d6d5b811
AWS_REGION=us-east-2

# Opção B: Variáveis diretas
RDS_HOST=your-rds-endpoint.amazonaws.com
RDS_USERNAME=admin
RDS_PASSWORD=your-password
RDS_DATABASE=personal_trainer_db
```

#### Executar Deploy

```bash
# Limpar ambiente e configurar
./setup-env.sh

# Fazer deploy
./deploy-ec2-rds.sh
```

### 3. Acessar Aplicação

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:3001
- **Health Check:** http://localhost:3001/health

> **Nota:** As aplicações são expostas diretamente nas portas 3000 e 3001. Para produção, recomenda-se usar um load balancer na frente.

## 🔧 Solução de Problemas

### Containers Reiniciando

Se os containers estiverem reiniciando constantemente:

```bash
# Verificar logs
docker-compose logs

# Limpar containers órfãos
docker-compose down --remove-orphans
docker rm -f personal_trainer_mysql

# Reconfigurar ambiente
./setup-env.sh
```

### Variáveis de Ambiente Não Configuradas

Se aparecer warnings sobre variáveis não configuradas:

```bash
# Criar e configurar .env
./create-env.sh
nano .env

# Verificar configurações
./setup-env.sh
```

### Testar Deploy

```bash
# Testar deploy sem nginx
./test-deploy-no-nginx.sh
```

## 📁 Estrutura do Projeto

```
projeto-personal/
├── backend/                 # API Node.js + TypeScript
│   ├── src/
│   │   ├── controllers/     # Controladores da API
│   │   ├── routes/          # Rotas da API
│   │   ├── services/        # Serviços (DB, AWS, etc.)
│   │   └── middleware/      # Middlewares
│   ├── prisma/              # Schema e migrações do banco
│   └── Dockerfile           # Container do backend
├── frontend/                # React + TypeScript
│   ├── src/
│   │   ├── components/      # Componentes React
│   │   ├── pages/           # Páginas da aplicação
│   │   └── contexts/        # Contextos React
│   └── Dockerfile           # Container do frontend
├── docker-compose.yml       # Orquestração dos containers
├── deploy-simple.sh         # Script de deploy simplificado
├── create-env.sh            # Criar arquivo .env
├── setup-env.sh             # Configurar ambiente
└── RDS_DEPLOY_README.md     # Documentação detalhada
```

## 🔧 Desenvolvimento

### Backend
```bash
cd backend
npm install
npm run dev
```

### Frontend
```bash
cd frontend
npm install
npm start
```

### Testar Build
```bash
./test-backend-build.sh
```

## �� Funcionalidades

- **Autenticação:** Login/registro de usuários
- **Gestão de Clientes:** Cadastro e controle de clientes
- **Pagamentos:** Controle de pagamentos e faturas
- **Dashboard:** Estatísticas e relatórios
- **Perfis:** Perfis de trainer e cliente

## 🔒 Segurança

- JWT para autenticação
- AWS Secrets Manager para credenciais
- Criptografia de senhas
- Rate limiting
- CORS configurado

## 🐳 Docker

### Comandos Úteis

```bash
# Ver status dos containers
docker-compose ps

# Ver logs
docker-compose logs -f

# Parar serviços
docker-compose down

# Reiniciar backend
docker-compose restart backend

# Limpar containers órfãos
docker-compose down --remove-orphans
```

## 📚 Documentação

- [Guia de Deploy com RDS](RDS_DEPLOY_README.md) - Documentação completa do deploy
- [API Documentation](API_DOCUMENTATION.md) - Documentação da API

## 🆘 Suporte

Para problemas:

1. Execute o deploy simplificado: `./deploy-simple.sh`
2. Verifique os logs: `docker-compose logs`
3. Teste a conectividade com RDS
4. Verifique as variáveis de ambiente: `./setup-env.sh`
5. Execute o script de teste: `./test-backend-build.sh`

## 🧹 Limpeza

Para remover arquivos antigos e desnecessários:

```bash
./cleanup-old-files.sh
```

---

**NH Personal Trainer** - Sistema completo para gerenciamento de personal trainers 