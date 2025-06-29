# 🚀 Deploy Simples - NH Personal Trainer

## 📋 O que foi organizado

✅ **1 Docker Compose** - Apenas `docker-compose.yml` para produção  
✅ **1 Script Único** - `deploy-ubuntu-ec2.sh` com todas as funcionalidades  
✅ **Sem Nginx** - Aplicação direta nas portas 3000 e 3001  
✅ **Otimizado para Ubuntu** - Script específico para Ubuntu Server  

## 🎯 Como Fazer o Deploy

### 1. Conectar à EC2 Ubuntu
```bash
ssh -i ~/.ssh/sua-chave.pem ubuntu@<IP-DA-EC2>
```

### 2. Clonar e executar
```bash
git clone https://github.com/nelsonholanda/personal.git projeto-personal
cd projeto-personal
chmod +x deploy-ubuntu-ec2.sh
./deploy-ubuntu-ec2.sh deploy
```

## 🔧 Comandos Principais

```bash
./deploy-ubuntu-ec2.sh deploy    # Deploy completo
./deploy-ubuntu-ec2.sh test      # Teste rápido
./deploy-ubuntu-ec2.sh logs      # Ver logs
./deploy-ubuntu-ec2.sh status    # Status dos containers
./deploy-ubuntu-ec2.sh restart   # Reiniciar
./deploy-ubuntu-ec2.sh help      # Ajuda
```

## 🌐 URLs da Aplicação

- **Frontend**: `http://<IP-DA-EC2>:3000`
- **Backend**: `http://<IP-DA-EC2>:3001`
- **Health Check**: `http://<IP-DA-EC2>:3001/health`

## 👤 Login Administrador

- **Email**: nholanda@nhpersonal.com
- **Senha**: P10r1988!

## ⚠️ Pré-requisitos

- Ubuntu Server 20.04+
- Security Groups: portas 22, 80, 443, 3000, 3001, 3306
- Instância t3.medium ou superior

---

**🎉 Pronto! Agora é só executar o script e a aplicação estará funcionando.** 