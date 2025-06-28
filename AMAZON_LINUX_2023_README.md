# Deploy no Amazon Linux 2023 - NH Personal Trainer

Este documento explica como fazer o deploy da aplicação NH Personal Trainer em uma instância EC2 com Amazon Linux 2023.

## 📋 Pré-requisitos

- Instância EC2 com Amazon Linux 2023
- Acesso SSH à instância
- Permissões de administrador (sudo)
- Repositório Git configurado

## 🚀 Scripts de Deploy Disponíveis

### 1. `deploy-ec2.sh` (Atualizado)
Script básico atualizado para Amazon Linux 2023:
- Usa `dnf` em vez de `apt`
- Instala Docker via repositório oficial
- Configuração básica de firewall

### 2. `deploy-amazon-linux-2023.sh` (Recomendado)
Script completo otimizado para Amazon Linux 2023:
- Verificação de compatibilidade do sistema
- Instalação otimizada do Docker e Docker Compose
- Configuração de firewall com firewalld
- Scripts de monitoramento e backup automático
- Limpeza automática de recursos Docker
- Logs coloridos e detalhados

### Opção 3: Script Sem Dependência do curl (Alternativa)
Se você estiver enfrentando problemas com o curl, use esta versão:
```bash
# Conectar via SSH
ssh -i sua-chave.pem ec2-user@seu-ip-ec2

# Baixar e executar o script (usando wget)
wget https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/deploy-amazon-linux-2023-no-curl.sh
chmod +x deploy-amazon-linux-2023-no-curl.sh
./deploy-amazon-linux-2023-no-curl.sh
```

## 🔧 Como Usar

### Opção 1: Script Básico
```bash
# Conectar via SSH
ssh -i sua-chave.pem ec2-user@seu-ip-ec2

# Baixar e executar o script
curl -O https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/deploy-ec2.sh
chmod +x deploy-ec2.sh
./deploy-ec2.sh
```

### Opção 2: Script Completo (Recomendado)
```bash
# Conectar via SSH
ssh -i sua-chave.pem ec2-user@seu-ip-ec2

# Baixar e executar o script
curl -O https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/deploy-amazon-linux-2023.sh
chmod +x deploy-amazon-linux-2023.sh
./deploy-amazon-linux-2023.sh
```

## 🚨 Resolução de Problemas

### Conflito do curl
Se você encontrar um erro de conflito do curl como este:
```
Problem: problem with installed package curl-minimal-8.11.1-4.amzn2023.0.1.x86_64
- package curl-minimal-8.11.1-4.amzn2023.0.1.x86_64 from @System conflicts with curl provided by curl-7.87.0-2.amzn2023.0.2.x86_64 from amazonlinux
```

**Solução 1: Usar o script de resolução**
```bash
# Baixar e executar o script de resolução
curl -O https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/fix-curl-conflict.sh
chmod +x fix-curl-conflict.sh
./fix-curl-conflict.sh
```

**Solução 2: Resolução manual**
```bash
# Opção A: Permitir substituição de pacotes
sudo dnf install -y --allowerasing curl

# Opção B: Remover curl-minimal e instalar curl completo
sudo dnf remove -y curl-minimal
sudo dnf install -y curl

# Opção C: Usar curl-minimal (geralmente funciona)
# Não fazer nada - curl-minimal é suficiente para o deploy
```

**Solução 3: Pular pacotes problemáticos
```bash
# Continuar com a instalação ignorando conflitos
sudo dnf install -y --skip-broken git wget unzip jq
```

### Verificar se curl está funcionando
```bash
# Testar funcionalidade básica
curl --version

# Testar download
curl -L -o /tmp/test https://httpbin.org/bytes/100

# Testar requisição HTTP
curl -s https://httpbin.org/get
```

## 🔄 Principais Diferenças do Amazon Linux 2023

### Gerenciador de Pacotes
- **Ubuntu/Debian**: `apt update && apt install`
- **Amazon Linux 2023**: `dnf update && dnf install`

### Firewall
- **Ubuntu**: `ufw` (Uncomplicated Firewall)
- **Amazon Linux 2023**: `firewalld` (FirewallD)

### Usuário Padrão
- **Ubuntu**: `ubuntu`
- **Amazon Linux 2023**: `ec2-user`

### Repositórios
- **Ubuntu**: repositórios Ubuntu
- **Amazon Linux 2023**: repositórios Amazon Linux + EPEL

## 📦 Pacotes Instalados

### Dependências Básicas
- `git` - Controle de versão
- `curl` - Transferência de dados
- `wget` - Download de arquivos
- `unzip` - Descompactação
- `jq` - Processamento JSON

### Docker
- Docker Engine
- Docker Compose (versão mais recente)

## 🔒 Configuração de Segurança

### Firewall (firewalld)
O script configura automaticamente:
- Porta 80 (HTTP)
- Porta 443 (HTTPS)
- Porta 3001 (API Backend)

### Usuário Docker
- Adiciona o usuário ao grupo `docker`
- Permite executar Docker sem sudo

## 📊 Monitoramento

### Script de Monitoramento
O script cria um arquivo `monitor.sh` que:
- Verifica status dos containers a cada 5 minutos
- Monitora uso de memória
- Registra logs em `/var/log/nh-personal/monitor.log`

### Como Usar
```bash
# Executar monitoramento
./monitor.sh

# Ver logs de monitoramento
tail -f /var/log/nh-personal/monitor.log
```

## 💾 Backup Automático

### Script de Backup
O script cria um arquivo `backup.sh` que:
- Faz backup do banco de dados
- Faz backup dos logs
- Mantém apenas os últimos 7 backups
- Executa automaticamente às 2h da manhã

### Como Usar
```bash
# Backup manual
./backup.sh

# Verificar backups
ls -la /var/log/nh-personal/backups/
```

## 🧹 Limpeza Automática

### Docker Cleanup
O script configura limpeza automática diária:
- Remove containers parados
- Remove imagens não utilizadas
- Remove volumes não utilizados
- Remove redes não utilizadas

## 🔍 Verificação do Deploy

### Endpoints de Verificação
- **Frontend**: `http://IP-PUBLICO:3000`
- **Backend**: `http://IP-PUBLICO:3001`
- **Health Check**: `http://IP-PUBLICO:3001/health`

### Comandos Úteis
```bash
# Verificar status dos containers
sudo docker-compose -f docker-compose.prod.yml ps

# Ver logs em tempo real
sudo docker-compose -f docker-compose.prod.yml logs -f

# Reiniciar serviços
sudo docker-compose -f docker-compose.prod.yml restart

# Parar todos os serviços
sudo docker-compose -f docker-compose.prod.yml down
```

## 🚨 Troubleshooting

### Problema: Docker não inicia
```bash
# Verificar status do serviço
sudo systemctl status docker

# Reiniciar Docker
sudo systemctl restart docker
```

### Problema: Portas bloqueadas
```bash
# Verificar firewall
sudo firewall-cmd --list-all

# Adicionar porta manualmente
sudo firewall-cmd --permanent --add-port=3001/tcp
sudo firewall-cmd --reload
```

### Problema: Permissões Docker
```bash
# Recarregar grupos
newgrp docker

# Verificar se usuário está no grupo
groups $USER
```

## 📞 Suporte

Se encontrar problemas:
1. Verifique os logs: `sudo docker-compose -f docker-compose.prod.yml logs`
2. Verifique o status dos serviços: `sudo docker-compose -f docker-compose.prod.yml ps`
3. Consulte este documento
4. Entre em contato com o suporte

## 🔄 Atualizações

Para atualizar a aplicação:
```bash
# Parar serviços
sudo docker-compose -f docker-compose.prod.yml down

# Atualizar código
git pull origin main

# Reconstruir e iniciar
sudo docker-compose -f docker-compose.prod.yml up --build -d
```

---

**Nota**: Este script foi otimizado especificamente para Amazon Linux 2023. Para outras distribuições, use o script `deploy-production.sh`. 