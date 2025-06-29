# NH Personal Trainer

Sistema completo de gerenciamento para personal trainers, incluindo controle de clientes, pagamentos e treinos.

## 🚀 Deploy Rápido

### Pré-requisitos

* Ubuntu Server 20.04 ou superior
* Instância EC2 t3.medium ou superior
* Security Groups configurados para portas 22, 80, 443, 3000, 3001, 3306

### Deploy Automático

```bash
# 1. Conectar à EC2 Ubuntu
ssh -i ~/.ssh/sua-chave.pem ubuntu@<IP-DA-EC2>

# 2. Clonar e executar
git clone https://github.com/nelsonholanda/personal.git projeto-personal
cd projeto-personal
chmod +x deploy-ubuntu-ec2.sh
./deploy-ubuntu-ec2.sh deploy
```

### Comandos Disponíveis

```bash
./deploy-ubuntu-ec2.sh deploy    # Deploy completo
./deploy-ubuntu-ec2.sh test      # Teste rápido
./deploy-ubuntu-ec2.sh features  # Teste completo das funcionalidades
./deploy-ubuntu-ec2.sh diagnose  # Diagnóstico completo
./deploy-ubuntu-ec2.sh logs      # Ver logs
./deploy-ubuntu-ec2.sh status    # Status dos containers
./deploy-ubuntu-ec2.sh restart   # Reiniciar
./deploy-ubuntu-ec2.sh stop      # Parar
./deploy-ubuntu-ec2.sh cleanup   # Limpar
./deploy-ubuntu-ec2.sh backup    # Backup do banco
./deploy-ubuntu-ec2.sh help      # Ajuda
```

## 🌐 URLs da Aplicação

Após o deploy bem-sucedido:

- **Frontend**: `http://<IP-DA-EC2>:3000`
- **Backend**: `http://<IP-DA-EC2>:3001`
- **Health Check**: `http://<IP-DA-EC2>:3001/health`

## 👤 Credenciais de Administrador

⚠️ **IMPORTANTE**: As credenciais de administrador são configuradas automaticamente durante o deploy.

```bash
# Configurar credenciais de administrador (se necessário)
sudo docker-compose exec backend node scripts/create-admin-user.js
```

**Nota**: Por segurança, as credenciais não são expostas nos READMEs.

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
├── database/                # Scripts de inicialização do banco
├── docker-compose.yml       # Orquestração dos containers
├── deploy-ubuntu-ec2.sh     # Script único de deploy
├── README_UBUNTU_EC2.md     # Documentação completa
├── DEPLOY_SIMPLES.md        # Instruções rápidas
└── env.example              # Exemplo de variáveis de ambiente
```

## 🔧 Funcionalidades

* **Autenticação:** Login/registro de usuários
* **Gestão de Clientes:** Cadastro e controle de clientes
* **Pagamentos:** Controle de pagamentos e faturas
* **Dashboard:** Estatísticas e relatórios
* **Perfis:** Perfis de trainer e cliente

## 🔒 Segurança

* JWT para autenticação
* AWS Secrets Manager para credenciais
* Criptografia de senhas
* Rate limiting
* CORS configurado
* Firewall UFW configurado automaticamente

## 🐳 Docker

### Comandos Úteis

```bash
# Ver status dos containers
sudo docker-compose ps

# Ver logs
sudo docker-compose logs -f

# Parar serviços
sudo docker-compose down

# Reiniciar backend
sudo docker-compose restart backend

# Limpar containers órfãos
sudo docker-compose down --remove-orphans
```

## 🐛 Solução de Problemas

### Problema: Docker não está instalado
O script instala automaticamente o Docker. Se houver problemas:

```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker
```

### Problema: Containers não iniciam
```bash
# Verificar logs
./deploy-ubuntu-ec2.sh logs

# Reiniciar
./deploy-ubuntu-ec2.sh restart

# Se não funcionar, fazer deploy novamente
./deploy-ubuntu-ec2.sh deploy
```

### Problema: Backend não responde
```bash
# Verificar logs do backend
sudo docker-compose logs backend

# Verificar se o banco está acessível
sudo docker-compose exec backend npx prisma db push
```

## 📈 Backup

### Backup automático do banco:
```bash
./deploy-ubuntu-ec2.sh backup
```

Os backups são salvos em `/var/log/nh-personal/backups/`

## 🔄 Atualizações

Para atualizar a aplicação:

```bash
# Fazer pull das mudanças
git pull origin main

# Reconstruir e reiniciar
./deploy-ubuntu-ec2.sh stop
./deploy-ubuntu-ec2.sh deploy
```

## 📞 Comandos Úteis

### Acessar container específico:
```bash
# Backend
sudo docker-compose exec backend bash

# MySQL
sudo docker-compose exec mysql mysql -u root -p
```

### Ver uso de recursos:
```bash
sudo docker stats
```

### Verificar portas em uso:
```bash
sudo netstat -tlnp | grep -E ':(80|443|3000|3001|3306)'
```

## ⚠️ Importante

- **Sistema**: Use Ubuntu Server para melhor compatibilidade
- **Security Groups**: Configure as portas necessárias na AWS
- **Credenciais**: Altere as senhas após o primeiro acesso
- **Backup**: Configure backup automático para produção

---

**NH Personal Trainer** - Sistema completo para gerenciamento de personal trainers

## Sobre

Sistema de gerenciamento completo para personal trainers desenvolvido com Node.js, React, TypeScript e Docker.

## 📊 Monitoramento

### Verificar se está funcionando:
```bash
./deploy-ubuntu-ec2.sh test
```

### Testar todas as funcionalidades:
```bash
./deploy-ubuntu-ec2.sh features
```

Este comando testa:
- ✅ Página inicial (Home)
- ✅ Login de administrador
- ✅ Gestão de clientes (listar e criar)
- ✅ Gestão de pagamentos (listar e criar)
- ✅ Frequência de clientes
- ✅ Relatórios por período
- ✅ Relatórios financeiros (recebidos e a receber)
- ✅ Dashboard
- ✅ Páginas do frontend (login, clientes, pagamentos, relatórios)

### Ver logs em tempo real:
```bash
./deploy-ubuntu-ec2.sh logs
``` 