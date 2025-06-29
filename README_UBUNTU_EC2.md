# 🚀 Deploy NH Personal Trainer - Ubuntu EC2

Script único e completo para fazer deploy da aplicação NH Personal Trainer em uma instância Ubuntu EC2 da AWS.

## 📋 Pré-requisitos

- **Sistema Operacional**: Ubuntu Server 20.04 ou superior
- **Tipo de Instância**: t3.medium ou superior
- **Armazenamento**: 20GB ou superior
- **Security Groups**: Portas 22, 80, 443, 3000, 3001, 3306

## 🎯 Deploy Rápido

### 1. Conectar à EC2
```bash
ssh -i ~/.ssh/sua-chave.pem ubuntu@<IP-DA-EC2>
```

### 2. Clonar o repositório
```bash
git clone https://github.com/nelsonholanda/personal.git projeto-personal
cd projeto-personal
```

### 3. Executar deploy completo
```bash
chmod +x deploy-ubuntu-ec2.sh
./deploy-ubuntu-ec2.sh deploy
```

## 🔧 Comandos Disponíveis

O script `deploy-ubuntu-ec2.sh` oferece várias opções:

```bash
# Deploy completo (instala tudo e inicia a aplicação)
./deploy-ubuntu-ec2.sh deploy

# Diagnóstico completo (verifica status de tudo)
./deploy-ubuntu-ec2.sh diagnose

# Teste rápido (verifica se está funcionando)
./deploy-ubuntu-ec2.sh test

# Ver logs em tempo real
./deploy-ubuntu-ec2.sh logs

# Ver status dos containers
./deploy-ubuntu-ec2.sh status

# Reiniciar aplicação
./deploy-ubuntu-ec2.sh restart

# Parar aplicação
./deploy-ubuntu-ec2.sh stop

# Limpar containers e imagens antigas
./deploy-ubuntu-ec2.sh cleanup

# Fazer backup do banco de dados
./deploy-ubuntu-ec2.sh backup

# Mostrar ajuda
./deploy-ubuntu-ec2.sh help
```

## 🌐 URLs da Aplicação

Após o deploy bem-sucedido:

- **Frontend**: `http://<IP-DA-EC2>:3000`
- **Backend**: `http://<IP-DA-EC2>:3001`
- **Health Check**: `http://<IP-DA-EC2>:3001/health`

## 👤 Credenciais de Administrador

- **Email**: nholanda@nhpersonal.com
- **Senha**: P10r1988!

## 📊 Monitoramento

### Verificar se está funcionando:
```bash
./deploy-ubuntu-ec2.sh test
```

### Ver logs em tempo real:
```bash
./deploy-ubuntu-ec2.sh logs
```

### Ver status dos containers:
```bash
./deploy-ubuntu-ec2.sh status
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

## 🔒 Segurança

### Firewall
O script configura automaticamente o UFW (Uncomplicated Firewall) com as regras necessárias.

### Atualizações
Para manter o sistema seguro:

```bash
sudo apt update && sudo apt upgrade -y
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

**🎉 Pronto! Agora você tem um script único e completo para gerenciar toda a aplicação na EC2 Ubuntu.** 