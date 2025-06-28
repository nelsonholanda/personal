# NH Personal Trainer

Sistema completo de gerenciamento para personal trainers, incluindo controle de clientes, pagamentos e treinos.

## 🚀 Deploy Rápido

### Pré-requisitos
- Docker e Docker Compose instalados
- Acesso ao Amazon RDS MySQL
- Configuração do AWS Secrets Manager (opcional)

### 1. Configurar Variáveis de Ambiente

```bash
cp env.example .env
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

### 2. Executar Deploy

```bash
chmod +x deploy-ec2-rds.sh
./deploy-ec2-rds.sh
```

### 3. Acessar Aplicação

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:3001
- **Health Check:** http://localhost/health

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
├── nginx/                   # Configuração do Nginx
├── docker-compose.yml       # Orquestração dos containers
├── deploy-ec2-rds.sh        # Script de deploy
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

## 📊 Funcionalidades

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
```

## 📚 Documentação

- [Guia de Deploy com RDS](RDS_DEPLOY_README.md) - Documentação completa do deploy
- [API Documentation](API_DOCUMENTATION.md) - Documentação da API

## 🆘 Suporte

Para problemas:

1. Verifique os logs: `docker-compose logs`
2. Teste a conectividade com RDS
3. Verifique as variáveis de ambiente
4. Execute o script de teste: `./test-backend-build.sh`

## 🧹 Limpeza

Para remover arquivos antigos e desnecessários:

```bash
./cleanup-old-files.sh
```

---

**NH Personal Trainer** - Sistema completo para gerenciamento de personal trainers 