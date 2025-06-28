# 🚀 NH Personal Trainer - Guia de Produção

## 📋 Visão Geral

Este é o sistema de gestão para personal trainers, configurado e otimizado para produção. O sistema inclui:

- **Frontend**: React com TypeScript
- **Backend**: Node.js com Express e Prisma
- **Banco de Dados**: MySQL 8.0
- **Containerização**: Docker e Docker Compose
- **Proxy Reverso**: Nginx

## 🛠️ Requisitos do Sistema

### Mínimos
- **CPU**: 2 cores
- **RAM**: 4GB
- **Disco**: 20GB
- **Sistema**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+

### Recomendados
- **CPU**: 4 cores
- **RAM**: 8GB
- **Disco**: 50GB SSD
- **Sistema**: Ubuntu 22.04 LTS

### Software Necessário
- Docker 20.10+
- Docker Compose 2.0+
- Git
- curl

## 🚀 Deploy Rápido

### 1. Clone o Repositório
```bash
git clone <seu-repositorio>
cd projeto-personal
```

### 2. Configure as Variáveis de Ambiente
```bash
cp env.example .env
# Edite o arquivo .env com suas configurações
nano .env
```

### 3. Execute o Deploy
```bash
./deploy-production.sh
```

## ⚙️ Configuração Detalhada

### Variáveis de Ambiente (.env)

#### Configurações Básicas
```env
NODE_ENV=production
PORT=3001
FRONTEND_URL=https://seu-dominio.com
```

#### Banco de Dados
```env
DATABASE_URL=mysql://root:password@localhost:3306/personal_trainer_db
MYSQL_ROOT_PASSWORD=sua-senha-segura
MYSQL_DATABASE=personal_trainer_db
```

#### JWT (Segurança)
```env
JWT_ACCESS_TOKEN_SECRET=sua-chave-super-secreta-muito-longa
JWT_REFRESH_TOKEN_SECRET=sua-chave-refresh-super-secreta
```

#### AWS (Opcional)
```env
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=sua-access-key
AWS_SECRET_ACCESS_KEY=sua-secret-key
AWS_DATABASE_SECRET_NAME=rds!db-xxxxx
AWS_JWT_SECRET_NAME=nh-personal/jwt
```

### Configuração de Domínio

1. **Configure DNS**
   ```
   A    api.seu-dominio.com    -> IP_DO_SERVIDOR
   A    seu-dominio.com        -> IP_DO_SERVIDOR
   ```

2. **Configure SSL com Let's Encrypt**
   ```bash
   sudo apt install certbot
   sudo certbot --nginx -d seu-dominio.com -d api.seu-dominio.com
   ```

3. **Atualize o Nginx**
   - Edite `nginx/nginx.prod.conf`
   - Configure os domínios
   - Reinicie: `docker-compose restart nginx`

## 📊 Monitoramento

### Scripts Automáticos

#### Monitoramento Contínuo
```bash
./monitor.sh
```

#### Backup Automático
```bash
./backup.sh
```

### Logs
```bash
# Ver todos os logs
docker-compose -f docker-compose.prod.yml logs -f

# Ver logs específicos
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f frontend
docker-compose -f docker-compose.prod.yml logs -f mysql
```

### Métricas
- **Backend**: http://localhost:9090/metrics
- **Nginx**: http://localhost/nginx_status

## 🔧 Manutenção

### Comandos Úteis

#### Reiniciar Serviços
```bash
# Reiniciar tudo
docker-compose -f docker-compose.prod.yml restart

# Reiniciar serviço específico
docker-compose -f docker-compose.prod.yml restart backend
```

#### Atualizar Aplicação
```bash
# Parar serviços
docker-compose -f docker-compose.prod.yml down

# Puxar código atualizado
git pull origin main

# Reconstruir e iniciar
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

#### Backup Manual
```bash
./backup.sh
```

#### Restaurar Backup
```bash
# Parar aplicação
docker-compose -f docker-compose.prod.yml down

# Restaurar banco
docker-compose -f docker-compose.prod.yml up -d mysql
sleep 30
docker-compose -f docker-compose.prod.yml exec mysql mysql -u root -p personal_trainer_db < backup/arquivo_backup.sql

# Reiniciar aplicação
docker-compose -f docker-compose.prod.yml up -d
```

## 🔒 Segurança

### Firewall
```bash
# Configurar UFW
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3001/tcp
```

### SSL/TLS
- Use Let's Encrypt para certificados gratuitos
- Configure renovação automática
- Force HTTPS em todas as conexões

### Senhas e Chaves
- Use senhas fortes (mínimo 16 caracteres)
- Rotacione chaves JWT regularmente
- Use variáveis de ambiente para secrets
- Nunca commite secrets no Git

## 📈 Performance

### Otimizações Aplicadas

#### Frontend
- Source maps desabilitados em produção
- Minificação de CSS/JS
- Compressão gzip
- Cache de assets estáticos

#### Backend
- Rate limiting configurado
- Compressão habilitada
- Pool de conexões otimizado
- Logs estruturados

#### Banco de Dados
- Índices otimizados
- Pool de conexões configurado
- Backup automático

### Monitoramento de Performance
```bash
# Ver uso de recursos
docker stats

# Ver logs de performance
docker-compose -f docker-compose.prod.yml logs backend | grep "performance"
```

## 🆘 Troubleshooting

### Problemas Comuns

#### Serviço não inicia
```bash
# Verificar logs
docker-compose -f docker-compose.prod.yml logs [servico]

# Verificar status
docker-compose -f docker-compose.prod.yml ps

# Reiniciar serviço
docker-compose -f docker-compose.prod.yml restart [servico]
```

#### Banco de dados não conecta
```bash
# Verificar se MySQL está rodando
docker-compose -f docker-compose.prod.yml ps mysql

# Testar conexão
docker-compose -f docker-compose.prod.yml exec mysql mysql -u root -p

# Verificar logs do MySQL
docker-compose -f docker-compose.prod.yml logs mysql
```

#### Frontend não carrega
```bash
# Verificar se está rodando
curl http://localhost:3000

# Verificar logs
docker-compose -f docker-compose.prod.yml logs frontend

# Verificar Nginx
docker-compose -f docker-compose.prod.yml logs nginx
```

### Logs de Erro
- **Backend**: `/var/log/nh-personal/backend.log`
- **Frontend**: `/var/log/nh-personal/frontend.log`
- **Nginx**: `/var/log/nh-personal/nginx.log`
- **MySQL**: `/var/log/nh-personal/mysql.log`

## 📞 Suporte

### Contatos
- **Email**: suporte@nhpersonal.com
- **Telefone**: (11) 99999-9999
- **WhatsApp**: (11) 99999-9999

### Informações para Suporte
Quando solicitar suporte, forneça:
1. Versão do sistema
2. Logs de erro
3. Configuração do ambiente
4. Passos para reproduzir o problema

### Documentação Adicional
- [API Documentation](./API_DOCUMENTATION.md)
- [Database Schema](./backend/prisma/schema.prisma)
- [Frontend Components](./frontend/src/components/)

## 📝 Changelog

### Versão 1.0.0 (2024-01-XX)
- ✅ Sistema completo de gestão de personal trainers
- ✅ Interface moderna e responsiva
- ✅ Autenticação segura
- ✅ Gestão de clientes e pagamentos
- ✅ Relatórios e analytics
- ✅ Configuração para produção
- ✅ Backup e monitoramento automático

---

**© 2024 NH Personal Trainer. Todos os direitos reservados.** 

ENCRYPTION_KEY=nh-personal-encryption-key-2024
DB_HOST=personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com
DB_PORT=3306
DB_USERNAME=admin
DB_PASSWORD_ENCRYPTED=...<senha criptografada>...
DB_NAME=personal_trainer_db 