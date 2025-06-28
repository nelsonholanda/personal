# Alterações para Suporte ao Amazon Linux 2023

## 📋 Resumo das Alterações

Este documento lista todas as alterações feitas para suportar o deploy no Amazon Linux 2023 e corrigir os erros de TypeScript.

## 🔧 Scripts de Deploy Atualizados

### 1. `deploy-ec2.sh` (Atualizado)
**Alterações principais:**
- Substituído `apt` por `dnf` (gerenciador de pacotes do Amazon Linux 2023)
- Instalação do Docker via `dnf install -y docker`
- Configuração do serviço Docker com `systemctl`
- Instalação manual do Docker Compose via curl
- Adição de `newgrp docker` para recarregar grupos

**Comandos alterados:**
```bash
# Antes (Ubuntu)
sudo apt update
sudo apt install -y docker.io docker-compose git curl

# Depois (Amazon Linux 2023)
sudo dnf update -y
sudo dnf install -y git curl wget
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
```

### 2. `deploy-amazon-linux-2023.sh` (Novo)
**Recursos adicionais:**
- Verificação de compatibilidade do sistema
- Instalação otimizada do Docker e Docker Compose
- Configuração de firewall com firewalld
- Scripts de monitoramento e backup automático
- Limpeza automática de recursos Docker
- Logs coloridos e detalhados
- Configuração de crontab para backup diário

## 🐛 Correções de TypeScript

### 1. `clientManagementController.ts`
**Problema:** Parâmetros de callback em funções `reduce` sem tipos explícitos.

**Solução:** Adicionadas anotações de tipo para todos os parâmetros:
```typescript
// Antes
const clientsWithStats = clients.map(client => {
  const totalPaid = client.subscriptions.reduce((sum, sub) => {
    return sum + sub.payments.reduce((paymentSum, payment) => {
      return paymentSum + (payment.status === 'paid' ? Number(payment.amount) : 0);
    }, 0);
  }, 0);
});

// Depois
const clientsWithStats = clients.map((client: any) => {
  const totalPaid = client.subscriptions.reduce((sum: number, sub: any) => {
    return sum + sub.payments.reduce((paymentSum: number, payment: any) => {
      return paymentSum + (payment.status === 'paid' ? Number(payment.amount) : 0);
    }, 0);
  }, 0);
});
```

### 2. `paymentController.ts`
**Problema:** Parâmetro `installment` sem tipo explícito.

**Solução:** Adicionada anotação de tipo:
```typescript
// Antes
updatedPayment.installments.map(installment =>

// Depois
updatedPayment.installments.map((installment: any) =>
```

### 3. `authController.ts`
**Problema:** Método `refreshToken` não existia no controller.

**Solução:** Implementado método `refreshToken` completo:
```typescript
refreshToken: async (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        error: 'Refresh token é obrigatório'
      });
    }

    // Verificar o refresh token
    const decoded = jwt.verify(
      refreshToken,
      process.env.JWT_REFRESH_TOKEN_SECRET || 'nh-personal-refresh-token-secret-2024'
    ) as any;

    // Buscar o usuário
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        role: true,
        isActive: true
      }
    });

    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        error: 'Token inválido ou usuário inativo'
      });
    }

    // Gerar novo access token
    const newAccessToken = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_ACCESS_TOKEN_SECRET || 'nh-personal-access-token-secret-2024',
      { expiresIn: '24h' }
    );

    return res.json({
      success: true,
      data: {
        accessToken: newAccessToken,
        user: {
          id: user.id,
          email: user.email,
          role: user.role
        }
      }
    });
  } catch (error) {
    console.error('Refresh token error:', error);
    return res.status(401).json({
      success: false,
      error: 'Token inválido'
    });
  }
}
```

## 📁 Arquivos Criados/Modificados

### Arquivos Modificados:
1. `deploy-ec2.sh` - Atualizado para Amazon Linux 2023
2. `backend/src/controllers/clientManagementController.ts` - Corrigidos tipos TypeScript
3. `backend/src/controllers/paymentController.ts` - Corrigido tipo TypeScript
4. `backend/src/controllers/authController.ts` - Adicionado método refreshToken

### Arquivos Criados:
1. `deploy-amazon-linux-2023.sh` - Script completo para Amazon Linux 2023
2. `AMAZON_LINUX_2023_README.md` - Documentação específica
3. `DEPLOY_AMAZON_LINUX_CHANGES.md` - Este arquivo de mudanças

## ✅ Resultados

### Antes das Correções:
```
ERROR [backend  6/10] RUN npm run build
src/controllers/clientManagementController.ts(80,44): error TS7006: Parameter 'client' implicitly has an 'any' type.
src/controllers/clientManagementController.ts(81,56): error TS7006: Parameter 'sum' implicitly has an 'any' type.
...
src/routes/auth.ts(10,46): error TS2339: Property 'refreshToken' does not exist on type...
```

### Depois das Correções:
```
> nh-personal-backend@1.0.0 build
> tsc
```
✅ **Build executado com sucesso sem erros!**

## 🚀 Como Usar

### Para Amazon Linux 2023:
```bash
# Script básico
./deploy-ec2.sh

# Script completo (recomendado)
./deploy-amazon-linux-2023.sh
```

### Para outras distribuições:
```bash
# Ubuntu/Debian
./deploy-production.sh
```

## 🔍 Verificação

Após o deploy, verifique:
1. Status dos containers: `sudo docker-compose -f docker-compose.prod.yml ps`
2. Logs: `sudo docker-compose -f docker-compose.prod.yml logs -f`
3. Health check: `curl http://IP-PUBLICO:3001/health`

## 📞 Suporte

Se encontrar problemas:
1. Verifique a documentação em `AMAZON_LINUX_2023_README.md`
2. Consulte os logs de erro
3. Entre em contato com o suporte

---

**Status:** ✅ **Concluído com sucesso**
**Data:** $(date)
**Versão:** 2.0.0 - Amazon Linux 2023 