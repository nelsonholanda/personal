# NH-Personal API Documentation

Documentação completa da API REST do sistema NH-Personal para gestão de personal trainers.

## 📋 Visão Geral

- **Base URL**: `http://localhost:3001/api`
- **Versão**: v1.0
- **Formato**: JSON
- **Autenticação**: JWT Bearer Token
- **Banco de Dados**: MySQL 8.0 via RDS AWS
- **Host RDS**: `personal-db.cbkc0cg2c7in.us-east-2.rds.amazonaws.com`

## 🔐 Autenticação

A API utiliza JWT (JSON Web Tokens) para autenticação. Todos os endpoints protegidos requerem o header `Authorization: Bearer <token>`.

### Login
```http
POST /auth/login
```

**Request Body:**
```json
{
  "email": "nholanda@nhpersonal.com",
  "password": "rdms95gn"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "Nholanda",
      "email": "nholanda@nhpersonal.com",
      "role": "admin"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### Registro
```http
POST /auth/register
```

**Request Body:**
```json
{
  "name": "João Silva",
  "email": "trainer@example.com",
  "password": "password123",
  "role": "trainer",
  "phone": "(11) 99999-9999"
}
```

## 🔐 Gerenciamento de Senhas

### Alterar Própria Senha
```http
POST /api/passwords/change
Authorization: Bearer <token>
Content-Type: application/json

{
  "currentPassword": "senha_atual",
  "newPassword": "NovaSenha123!"
}
```

**Resposta:**
```json
{
  "success": true,
  "message": "Senha alterada com sucesso"
}
```

### Solicitar Reset de Senha
```http
POST /api/passwords/request-reset
Content-Type: application/json

{
  "email": "usuario@exemplo.com"
}
```

**Resposta:**
```json
{
  "success": true,
  "message": "Se o email existir, você receberá um link para reset de senha"
}
```

### Reset de Senha com Token
```http
POST /api/passwords/reset
Content-Type: application/json

{
  "token": "token_de_reset",
  "newPassword": "NovaSenha123!"
}
```

**Resposta:**
```json
{
  "success": true,
  "message": "Senha redefinida com sucesso"
}
```

### Verificar Se Precisa Alterar Senha
```http
GET /api/passwords/check-change-required
Authorization: Bearer <token>
```

**Resposta:**
```json
{
  "success": true,
  "data": {
    "passwordChangeRequired": false
  }
}
```

### Gerar Senha Segura
```http
POST /api/passwords/generate
Authorization: Bearer <token>
Content-Type: application/json

{
  "length": 12
}
```

**Resposta:**
```json
{
  "success": true,
  "data": {
    "password": "Kj9#mN2$pL5",
    "length": 12
  }
}
```

### Alterar Senha de Usuário (Admin)
```http
POST /api/passwords/change-user
Authorization: Bearer <token>
Content-Type: application/json

{
  "userId": 2,
  "newPassword": "NovaSenha123!",
  "forceChange": true
}
```

**Resposta:**
```json
{
  "success": true,
  "message": "Senha do usuário João Silva alterada com sucesso"
}
```

### Forçar Mudança de Senha (Admin)
```http
POST /api/passwords/force-change/2
Authorization: Bearer <token>
```

**Resposta:**
```json
{
  "success": true,
  "message": "Usuário João Silva será obrigado a alterar a senha na próxima sessão"
}
```

### Histórico de Senhas (Admin)
```http
GET /api/passwords/history/2
Authorization: Bearer <token>
```

**Resposta:**
```json
{
  "success": true,
  "data": {
    "history": [
      {
        "id": 1,
        "changedAt": "2024-01-15T10:30:00.000Z"
      },
      {
        "id": 2,
        "changedAt": "2024-01-10T14:20:00.000Z"
      }
    ],
    "count": 2
  }
}
```

### Limpar Tokens Expirados (Cron Job)
```http
POST /api/passwords/cleanup-tokens
Authorization: Bearer <token>
```

**Resposta:**
```json
{
  "success": true,
  "message": "Tokens expirados limpos com sucesso"
}
```

## 👥 Gestão de Clientes

### Listar Clientes
```http
GET /client-management?status=active&page=1&limit=10
```

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `status` (optional): active, inactive, suspended, completed
- `page` (optional): número da página (default: 1)
- `limit` (optional): itens por página (default: 10)

**Response:**
```json
{
  "success": true,
  "data": {
    "clients": [
      {
        "id": 1,
        "client": {
          "id": 2,
          "name": "Maria Santos",
          "email": "maria@example.com",
          "phone": "(11) 88888-8888",
          "profileImageUrl": "https://example.com/avatar.jpg"
        },
        "status": "active",
        "weeklySessions": 3,
        "sessionDurationMinutes": 60,
        "startDate": "2024-01-15",
        "financialStats": {
          "totalPaid": 1500.00,
          "totalPending": 500.00,
          "totalOverdue": 0.00
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 25,
      "pages": 3
    }
  }
}
```

### Obter Cliente Específico
```http
GET /client-management/{id}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "client": {
      "id": 2,
      "name": "Maria Santos",
      "email": "maria@example.com",
      "phone": "(11) 88888-8888",
      "birthDate": "1990-05-15",
      "gender": "female",
      "height": 165.0,
      "weight": 65.0,
      "profileImageUrl": "https://example.com/avatar.jpg",
      "clientProfile": {
        "fitnessGoals": "Perder peso e ganhar massa muscular",
        "medicalConditions": "Nenhuma",
        "emergencyContact": "João Santos",
        "emergencyPhone": "(11) 77777-7777"
      }
    },
    "status": "active",
    "weeklySessions": 3,
    "sessionDurationMinutes": 60,
    "startDate": "2024-01-15",
    "subscriptions": [
      {
        "id": 1,
        "paymentPlan": {
          "name": "Plano Avançado",
          "price": 350.00
        },
        "payments": [
          {
            "id": 1,
            "amount": 350.00,
            "status": "paid",
            "paymentMethod": {
              "name": "PIX"
            }
          }
        ]
      }
    ]
  }
}
```

### Adicionar Cliente
```http
POST /client-management
```

**Request Body:**
```json
{
  "clientId": 2,
  "weeklySessions": 3,
  "sessionDurationMinutes": 60,
  "notes": "Cliente interessado em hipertrofia"
}
```

### Atualizar Cliente
```http
PUT /client-management/{id}
```

**Request Body:**
```json
{
  "status": "active",
  "weeklySessions": 4,
  "sessionDurationMinutes": 90,
  "notes": "Aumentou frequência de treinos"
}
```

### Remover Cliente
```http
DELETE /client-management/{id}
```

### Estatísticas Financeiras
```http
GET /client-management/stats/financial?startDate=2024-01-01&endDate=2024-12-31
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalReceived": 15000.00,
    "totalPending": 2500.00,
    "totalOverdue": 500.00,
    "totalClients": 15,
    "paymentsByMethod": {
      "PIX": { "total": 8000.00, "count": 20 },
      "Cartão de Crédito": { "total": 5000.00, "count": 10 },
      "Dinheiro": { "total": 2000.00, "count": 5 }
    },
    "paymentsByClient": {
      "Maria Santos": { "total": 1500.00, "count": 3 },
      "João Silva": { "total": 1200.00, "count": 2 }
    }
  }
}
```

## 💰 Gestão de Pagamentos

### Listar Pagamentos
```http
GET /payments?status=pending&clientId=2&page=1&limit=10
```

**Query Parameters:**
- `status` (optional): pending, paid, overdue, cancelled
- `clientId` (optional): ID do cliente
- `startDate` (optional): data inicial (YYYY-MM-DD)
- `endDate` (optional): data final (YYYY-MM-DD)
- `page` (optional): número da página
- `limit` (optional): itens por página

**Response:**
```json
{
  "success": true,
  "data": {
    "payments": [
      {
        "id": 1,
        "amount": 350.00,
        "paymentDate": "2024-01-15",
        "dueDate": "2024-01-15",
        "status": "paid",
        "paymentReference": "PIX123456",
        "paymentMethod": {
          "id": 2,
          "name": "PIX"
        },
        "clientSubscription": {
          "id": 1,
          "paymentPlan": {
            "name": "Plano Avançado",
            "price": 350.00
          },
          "clientManagement": {
            "client": {
              "id": 2,
              "name": "Maria Santos",
              "email": "maria@example.com"
            }
          }
        },
        "installments": []
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 50,
      "pages": 5
    }
  }
}
```

### Criar Pagamento
```http
POST /payments
```

**Request Body:**
```json
{
  "clientSubscriptionId": 1,
  "paymentMethodId": 2,
  "amount": 350.00,
  "paymentDate": "2024-01-15",
  "dueDate": "2024-01-15",
  "paymentReference": "PIX123456",
  "notes": "Pagamento do plano avançado",
  "installments": 1
}
```

### Marcar como Pago
```http
PUT /payments/{id}/mark-paid
```

**Request Body:**
```json
{
  "paymentDate": "2024-01-15",
  "paymentReference": "PIX123456"
}
```

### Obter Métodos de Pagamento
```http
GET /payments/methods
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Dinheiro",
      "description": "Pagamento em dinheiro"
    },
    {
      "id": 2,
      "name": "PIX",
      "description": "Transferência via PIX"
    },
    {
      "id": 3,
      "name": "Cartão de Crédito",
      "description": "Pagamento com cartão de crédito"
    }
  ]
}
```

### Obter Planos de Pagamento
```http
GET /payments/plans
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Plano Básico",
      "description": "1 aula por semana",
      "price": 150.00,
      "durationWeeks": 4,
      "sessionsPerWeek": 1
    },
    {
      "id": 2,
      "name": "Plano Avançado",
      "description": "3 aulas por semana",
      "price": 350.00,
      "durationWeeks": 4,
      "sessionsPerWeek": 3
    }
  ]
}
```

## 🏋️ Gestão de Treinos

### Listar Planos de Treino
```http
GET /training-plans?trainerId=1&clientId=2
```

### Criar Plano de Treino
```http
POST /training-plans
```

**Request Body:**
```json
{
  "trainerId": 1,
  "clientId": 2,
  "name": "Plano Hipertrofia",
  "description": "Foco em ganho de massa muscular",
  "durationWeeks": 8,
  "startDate": "2024-01-15"
}
```

### Listar Treinos
```http
GET /workouts?trainingPlanId=1
```

### Criar Treino
```http
POST /workouts
```

**Request Body:**
```json
{
  "trainingPlanId": 1,
  "name": "Treino A - Peito e Tríceps",
  "description": "Treino focado em peito e tríceps",
  "durationMinutes": 60,
  "difficultyLevel": "intermediate",
  "dayOfWeek": 1,
  "orderInPlan": 1
}
```

### Listar Exercícios
```http
GET /exercises?difficultyLevel=intermediate&muscleGroups=chest
```

### Criar Exercício
```http
POST /exercises
```

**Request Body:**
```json
{
  "name": "Supino Reto",
  "description": "Exercício clássico para peito",
  "muscleGroups": ["chest", "triceps", "shoulders"],
  "equipmentNeeded": ["barbell", "bench", "weights"],
  "difficultyLevel": "intermediate",
  "instructions": "Deite no banco, segure a barra...",
  "videoUrl": "https://example.com/video.mp4"
}
```

## 📅 Agendamentos

### Listar Agendamentos
```http
GET /appointments?trainerId=1&startDate=2024-01-01&endDate=2024-01-31
```

### Criar Agendamento
```http
POST /appointments
```

**Request Body:**
```json
{
  "trainerId": 1,
  "clientId": 2,
  "appointmentDate": "2024-01-20",
  "startTime": "14:00:00",
  "endTime": "15:00:00",
  "type": "training",
  "location": "Academia Fitness",
  "isOnline": false,
  "notes": "Primeira sessão de treino"
}
```

## 📊 Progresso

### Listar Medidas de Progresso
```http
GET /progress?clientId=2&startDate=2024-01-01&endDate=2024-12-31
```

### Registrar Medida de Progresso
```http
POST /progress
```

**Request Body:**
```json
{
  "clientId": 2,
  "measurementDate": "2024-01-15",
  "weightKg": 65.0,
  "bodyFatPercentage": 18.5,
  "muscleMassKg": 45.0,
  "chestCm": 95.0,
  "waistCm": 75.0,
  "notes": "Primeira medição do mês"
}
```

## 💬 Mensagens

### Listar Mensagens
```http
GET /messages?senderId=1&receiverId=2
```

### Enviar Mensagem
```http
POST /messages
```

**Request Body:**
```json
{
  "senderId": 1,
  "receiverId": 2,
  "messageText": "Olá! Como está o treino?"
}
```

## 🔔 Notificações

### Listar Notificações
```http
GET /notifications?userId=1&type=payment
```

### Marcar como Lida
```http
PUT /notifications/{id}
```

**Request Body:**
```json
{
  "isRead": true
}
```

## 👤 Usuários

### Obter Perfil do Usuário
```http
GET /users/profile
```

### Atualizar Perfil
```http
PUT /users/profile
```

**Request Body:**
```json
{
  "name": "João Silva",
  "phone": "(11) 99999-9999",
  "birthDate": "1985-03-15",
  "gender": "male",
  "height": 180.0,
  "weight": 80.0
}
```

## 🚨 Códigos de Erro

### Erros Comuns

**400 - Bad Request**
```json
{
  "success": false,
  "error": "Dados inválidos",
  "details": {
    "email": "Email é obrigatório",
    "password": "Senha deve ter pelo menos 6 caracteres"
  }
}
```

**401 - Unauthorized**
```json
{
  "success": false,
  "error": "Token inválido ou expirado"
}
```

**403 - Forbidden**
```json
{
  "success": false,
  "error": "Acesso negado"
}
```

**404 - Not Found**
```json
{
  "success": false,
  "error": "Recurso não encontrado"
}
```

**500 - Internal Server Error**
```json
{
  "success": false,
  "error": "Erro interno do servidor"
}
```

## 📝 Paginação

Todas as listagens suportam paginação com os seguintes parâmetros:

- `page`: Número da página (default: 1)
- `limit`: Itens por página (default: 10, max: 100)

**Response com paginação:**
```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 100,
      "pages": 10
    }
  }
}
```

## 🔄 Rate Limiting

A API implementa rate limiting para prevenir abuso:

- **Limite**: 100 requisições por 15 minutos por IP
- **Headers de resposta**:
  - `X-RateLimit-Limit`: Limite de requisições
  - `X-RateLimit-Remaining`: Requisições restantes
  - `X-RateLimit-Reset`: Timestamp de reset

## 📊 Filtros e Busca

### Filtros Disponíveis

**Clientes:**
- `status`: active, inactive, suspended, completed
- `search`: busca por nome ou email

**Pagamentos:**
- `status`: pending, paid, overdue, cancelled
- `clientId`: ID do cliente
- `startDate`: data inicial
- `endDate`: data final

**Agendamentos:**
- `trainerId`: ID do trainer
- `clientId`: ID do cliente
- `type`: consultation, training, assessment, follow_up
- `startDate`: data inicial
- `endDate`: data final

### Exemplo de Uso
```http
GET /client-management?status=active&search=maria&page=1&limit=20
```

## 🔐 Segurança

### Headers Obrigatórios
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

### Validação de Dados
- Todos os endpoints validam dados de entrada
- Sanitização automática de strings
- Validação de tipos e formatos
- Verificação de permissões por role

### CORS
- Configurado para permitir requisições do frontend
- Headers de segurança habilitados
- Credenciais suportadas

## 📱 Webhooks (Futuro)

Planejado para futuras versões:
- Notificações de pagamento
- Lembretes de agendamento
- Atualizações de progresso
- Alertas de clientes em atraso

---

**NH-Personal API** - Documentação completa e atualizada para integração com o sistema de gestão de personal trainers. 