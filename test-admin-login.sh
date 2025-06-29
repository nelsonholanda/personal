#!/bin/bash

# Script de teste para verificar login do usuário admin
echo "🧪 Testando login do usuário admin 'nholanda'..."

# Testar login por nome de usuário
echo "🔐 Testando login por nome de usuário..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"name":"nholanda","password":"P10r1988!"}')

if echo "$LOGIN_RESPONSE" | grep -q "token\|access_token"; then
    echo "✅ Login por nome de usuário: OK"
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    echo "🔑 Token obtido: ${TOKEN:0:20}..."
else
    echo "❌ Login por nome de usuário: FALHOU"
    echo "Resposta: $LOGIN_RESPONSE"
    exit 1
fi

# Testar acesso ao dashboard
echo "📊 Testando acesso ao dashboard..."
DASHBOARD_RESPONSE=$(curl -s -f http://localhost:3001/api/dashboard \
    -H "Authorization: Bearer $TOKEN")

if echo "$DASHBOARD_RESPONSE" | grep -q "dashboard\|stats\|summary"; then
    echo "✅ Acesso ao dashboard: OK"
else
    echo "❌ Acesso ao dashboard: FALHOU"
    echo "Resposta: $DASHBOARD_RESPONSE"
fi

# Testar acesso à área admin
echo "👑 Testando acesso à área admin..."
ADMIN_RESPONSE=$(curl -s -f http://localhost:3001/api/admin/stats \
    -H "Authorization: Bearer $TOKEN")

if echo "$ADMIN_RESPONSE" | grep -q "stats\|users\|trainers"; then
    echo "✅ Acesso à área admin: OK"
else
    echo "❌ Acesso à área admin: FALHOU"
    echo "Resposta: $ADMIN_RESPONSE"
fi

echo "🎉 Testes concluídos!" 