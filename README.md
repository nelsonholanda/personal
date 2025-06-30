# 🏋️ NH Gestão de Alunos

Sistema completo para gestão de alunos e personal trainers, desenvolvido com React, Node.js, TypeScript e MySQL.

## 🚀 Funcionalidades

### 👥 Gestão de Usuários
- **Cadastro de Personal Trainers** com perfis completos
- **Gestão de Clientes** com histórico e progresso
- **Sistema de Autenticação** seguro com JWT
- **Controle de Acesso** por roles (admin, trainer, client)

### 💰 Gestão Financeira
- **Controle de Pagamentos** com status e histórico
- **Planos de Pagamento** personalizados
- **Relatórios Financeiros** detalhados
- **Notificações** de pagamentos pendentes

### 📅 Agendamento
- **Sistema de Agendamentos** com horários flexíveis
- **Sessões Online/Offline** com links de reunião
- **Lembretes Automáticos** para clientes
- **Calendário Integrado** com visualização clara

### 🏃‍♂️ Treinamento
- **Planos de Treino** personalizados
- **Exercícios** com descrições e vídeos
- **Acompanhamento de Progresso** com medições
- **Histórico de Treinos** completo

### 📊 Dashboard
- **Estatísticas em Tempo Real** de clientes e receita
- **Atividade Recente** com timeline
- **Próximas Sessões** organizadas
- **Métricas de Performance** detalhadas

## 🔐 Melhorias de Segurança Implementadas

### ✅ Criptografia de Senhas
- **Algoritmo:** AES-256-CBC
- **Chave:** 256 bits (32 bytes)
- **IV:** 128 bits (16 bytes)
- **Compatibilidade:** Total com autenticações existentes

### 🛡️ Proteção de Dados Sensíveis
- **Senhas de Banco:** Criptografadas automaticamente
- **Configurações:** Variáveis de ambiente seguras
- **Logs:** Senhas mascaradas em logs
- **Backup:** Configurações protegidas

### 🔑 Geração de Senhas Seguras
- **Complexidade:** Maiúsculas, minúsculas, números, símbolos
- **Tamanho:** Configurável (padrão: 16 caracteres)
- **Embaralhamento:** Algoritmo adicional de segurança

### 📋 Scripts de Segurança
```bash
# Testar funcionalidades de criptografia
npm run test:encryption

# Migrar senhas para criptografia (quando necessário)
npm run encrypt:passwords
```

## 🛠️ Tecnologias

### Frontend
- **React 18** com TypeScript
- **Tailwind CSS** para estilização
- **React Router** para navegação
- **React Hot Toast** para notificações
- **Axios** para requisições HTTP

### Backend
- **Node.js** com TypeScript
- **Express.js** para API REST
- **Prisma ORM** para banco de dados
- **JWT** para autenticação
- **bcrypt** para hash de senhas
- **AES-256-CBC** para criptografia

### Banco de Dados
- **MySQL** (RDS AWS)
- **Prisma Migrations** para versionamento
- **Relacionamentos** otimizados

### Infraestrutura
- **Docker** para containerização
- **Docker Compose** para orquestração
- **AWS RDS** para banco de dados
- **EC2** para hospedagem

## 🚀 Como Executar

### Pré-requisitos
- Node.js 18+
- Docker e Docker Compose
- MySQL 8.0+

### 1. Clone o repositório
```bash
git clone <repository-url>
cd projeto-personal
```

### 2. Configure as variáveis de ambiente
```bash
cp env.example .env
# Edite o arquivo .env com suas configurações
```

### 3. Execute com Docker
```bash
# Build e start da aplicação
docker-compose up --build

# Acesse: http://localhost:3000
```

### 4. Ou execute localmente
```bash
# Backend
cd backend
npm install
npm run dev

# Frontend (em outro terminal)
cd frontend
npm install
npm start
```

## 📁 Estrutura do Projeto

```
projeto-personal/
├── backend/                 # API Node.js/Express
│   ├── src/
│   │   ├── controllers/     # Controladores da API
│   │   ├── routes/          # Rotas da API
│   │   ├── services/        # Serviços (DB, Criptografia)
│   │   ├── middleware/      # Middlewares (Auth, Validação)
│   │   └── config/          # Configurações
│   ├── prisma/              # Schema e migrações do banco
│   └── scripts/             # Scripts de utilidade
├── frontend/                # Aplicação React
│   ├── src/
│   │   ├── components/      # Componentes reutilizáveis
│   │   ├── pages/           # Páginas da aplicação
│   │   ├── services/        # Serviços de API
│   │   ├── contexts/        # Contextos React
│   │   └── config/          # Configurações
│   └── public/              # Arquivos estáticos
├── docker-compose.yml       # Configuração Docker
├── Dockerfile              # Imagem Docker
└── README.md               # Documentação
```

## 🔧 Scripts Disponíveis

### Backend
```bash
npm run dev          # Desenvolvimento com nodemon
npm run build        # Compilar TypeScript
npm run test         # Executar testes
npm run test:encryption # Testar criptografia
npm run encrypt:passwords # Migrar senhas
```

### Frontend
```bash
npm start           # Desenvolvimento
npm run build       # Build de produção
npm test            # Executar testes
```

## 📊 Status do Projeto

### ✅ Implementado
- [x] Sistema de autenticação completo
- [x] Gestão de usuários (admin, trainer, client)
- [x] Dashboard com estatísticas
- [x] Gestão de clientes
- [x] Sistema de pagamentos
- [x] Agendamento de sessões
- [x] Planos de treino
- [x] Criptografia de dados sensíveis
- [x] Docker e deploy automatizado
- [x] Testes de segurança

### 🔄 Em Desenvolvimento
- [ ] Notificações push
- [ ] Relatórios avançados
- [ ] Integração com APIs externas
- [ ] App mobile

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 📞 Suporte

Para suporte, envie um email para [seu-email@exemplo.com] ou abra uma issue no GitHub.

---

**Desenvolvido com ❤️ para facilitar a gestão de personal trainers e seus clientes.** 