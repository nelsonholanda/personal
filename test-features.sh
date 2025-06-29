#!/bin/bash

# Script de Teste de Funcionalidades - NH Gestão de Alunos
# Versão: 1.0.0

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

echo "🧪 Teste Completo de Funcionalidades - NH Gestão de Alunos"
echo "=========================================================="

# Verificar se a aplicação está rodando
log "🔍 Verificando se a aplicação está rodando..."

if ! curl -f http://localhost:3001/health > /dev/null 2>&1; then
    error "Backend não está respondendo. Execute o deploy primeiro."
    exit 1
fi

if ! curl -f http://localhost:3000 > /dev/null 2>&1; then
    error "Frontend não está respondendo. Execute o deploy primeiro."
    exit 1
fi

success "Aplicação está rodando"

# Contador de testes
TESTS_PASSED=0
TESTS_FAILED=0

# Função para testar endpoint
test_endpoint() {
    local name="$1"
    local method="$2"
    local url="$3"
    local headers="$4"
    local data="$5"
    local expected_pattern="$6"
    
    log "Testando $name..."
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -f "$url" $headers 2>/dev/null || echo "FAILED")
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -X POST "$url" $headers -d "$data" 2>/dev/null || echo "FAILED")
    fi
    
    if echo "$response" | grep -q "$expected_pattern"; then
        success "   ✅ $name: OK"
        ((TESTS_PASSED++))
        return 0
    else
        error "   ❌ $name: FALHOU"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 1. Testar página inicial
test_endpoint "Página inicial" "GET" "http://localhost:3000" "" "" "html\|React\|NH Gestão"

# 2. Testar login de administrador
log "🔐 Testando login de administrador..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"nholanda@nhpersonal.com","password":"P10r1988!"}' 2>/dev/null || echo "FAILED")

if echo "$LOGIN_RESPONSE" | grep -q "token\|access_token"; then
    success "   ✅ Login administrador: OK"
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    ((TESTS_PASSED++))
else
    error "   ❌ Login administrador: FALHOU"
    ((TESTS_FAILED++))
fi

# Se o token foi obtido, testar funcionalidades que requerem autenticação
if [ ! -z "$TOKEN" ]; then
    AUTH_HEADER="-H \"Authorization: Bearer $TOKEN\""
    
    # 3. Testar gestão de clientes
    test_endpoint "Listagem de clientes" "GET" "http://localhost:3001/api/clients" "$AUTH_HEADER" "" "clients\|data\|[]"
    test_endpoint "Criação de cliente" "POST" "http://localhost:3001/api/clients" "$AUTH_HEADER -H \"Content-Type: application/json\"" '{"name":"Cliente Teste","email":"teste@teste.com","phone":"11999999999"}' "id\|name\|Cliente Teste"
    
    # 4. Testar gestão de pagamentos
    test_endpoint "Listagem de pagamentos" "GET" "http://localhost:3001/api/payments" "$AUTH_HEADER" "" "payments\|data\|[]"
    test_endpoint "Criação de pagamento" "POST" "http://localhost:3001/api/payments" "$AUTH_HEADER -H \"Content-Type: application/json\"" '{"clientId":1,"amount":100.00,"dueDate":"2024-12-31","status":"pending"}' "id\|amount\|100.00"
    
    # 5. Testar frequência de clientes
    test_endpoint "Frequência de clientes" "GET" "http://localhost:3001/api/clients/frequency" "$AUTH_HEADER" "" "frequency\|data\|[]"
    
    # 6. Testar relatórios
    test_endpoint "Relatório de pagamentos" "GET" "http://localhost:3001/api/payments/report?startDate=2024-01-01&endDate=2024-12-31" "$AUTH_HEADER" "" "report\|data\|received\|pending"
    test_endpoint "Relatório financeiro" "GET" "http://localhost:3001/api/payments/financial-report?startDate=2024-01-01&endDate=2024-12-31" "$AUTH_HEADER" "" "financial\|received\|pending\|total"
    
    # 7. Testar dashboard
    test_endpoint "Dashboard" "GET" "http://localhost:3001/api/dashboard" "$AUTH_HEADER" "" "dashboard\|stats\|summary"
    
else
    warning "   ⚠️ Token não disponível - pulando testes que requerem autenticação"
    ((TESTS_FAILED++))
fi

# 8. Testar páginas do frontend
test_endpoint "Página de login" "GET" "http://localhost:3000/login" "" "" "html\|login\|form"
test_endpoint "Página de clientes" "GET" "http://localhost:3000/clients" "" "" "html\|clients\|management"
test_endpoint "Página de pagamentos" "GET" "http://localhost:3000/payments" "" "" "html\|payments\|financial"
test_endpoint "Página de relatórios" "GET" "http://localhost:3000/reports" "" "" "html\|reports\|analytics"

# 9. Testar funcionalidades específicas de relatórios
if [ ! -z "$TOKEN" ]; then
    log "📊 Testando funcionalidades específicas de relatórios..."
    
    # Testar relatório de recebidos vs a receber
    RECEIVED_REPORT=$(curl -s -f "http://localhost:3001/api/payments/received-report?startDate=2024-01-01&endDate=2024-12-31" \
        -H "Authorization: Bearer $TOKEN" 2>/dev/null || echo "FAILED")
    
    if echo "$RECEIVED_REPORT" | grep -q "received\|total\|amount"; then
        success "   ✅ Relatório de recebidos: OK"
        ((TESTS_PASSED++))
    else
        error "   ❌ Relatório de recebidos: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    # Testar relatório de a receber
    PENDING_REPORT=$(curl -s -f "http://localhost:3001/api/payments/pending-report?startDate=2024-01-01&endDate=2024-12-31" \
        -H "Authorization: Bearer $TOKEN" 2>/dev/null || echo "FAILED")
    
    if echo "$PENDING_REPORT" | grep -q "pending\|total\|amount"; then
        success "   ✅ Relatório de a receber: OK"
        ((TESTS_PASSED++))
    else
        error "   ❌ Relatório de a receber: FALHOU"
        ((TESTS_FAILED++))
    fi
    
    # Testar relatório de frequência por período
    FREQUENCY_REPORT=$(curl -s -f "http://localhost:3001/api/clients/frequency-report?startDate=2024-01-01&endDate=2024-12-31" \
        -H "Authorization: Bearer $TOKEN" 2>/dev/null || echo "FAILED")
    
    if echo "$FREQUENCY_REPORT" | grep -q "frequency\|data\|period"; then
        success "   ✅ Relatório de frequência por período: OK"
        ((TESTS_PASSED++))
    else
        error "   ❌ Relatório de frequência por período: FALHOU"
        ((TESTS_FAILED++))
    fi
fi

# Resultado final
echo ""
echo "📊 RESULTADO DOS TESTES DE FUNCIONALIDADES"
echo "=========================================="
echo "✅ Testes passaram: $TESTS_PASSED"
echo "❌ Testes falharam: $TESTS_FAILED"
echo "📊 Total de testes: $((TESTS_PASSED + TESTS_FAILED))"

if [ $((TESTS_PASSED + TESTS_FAILED)) -gt 0 ]; then
    SUCCESS_RATE=$((TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED)))
    echo "📈 Taxa de sucesso: ${SUCCESS_RATE}%"
fi

echo ""

# Recomendações baseadas nos resultados
if [ $TESTS_FAILED -eq 0 ]; then
    success "🎉 Todas as funcionalidades estão funcionando perfeitamente!"
    echo ""
    echo "✅ Funcionalidades testadas e funcionando:"
    echo "   • Página inicial (Home)"
    echo "   • Login de administrador"
    echo "   • Gestão de clientes (listar e criar)"
    echo "   • Gestão de pagamentos (listar e criar)"
    echo "   • Frequência de clientes"
    echo "   • Relatórios por período"
    echo "   • Relatórios financeiros (recebidos e a receber)"
    echo "   • Dashboard"
    echo "   • Páginas do frontend (login, clientes, pagamentos, relatórios)"
    echo "   • Relatórios específicos de recebidos vs a receber"
    echo "   • Relatórios de frequência por período"
elif [ $TESTS_FAILED -lt 5 ]; then
    warning "⚠️ A maioria das funcionalidades está funcionando, mas alguns problemas foram encontrados."
    echo "   Verifique os logs: sudo docker-compose logs"
else
    error "❌ Muitas funcionalidades falharam. Verifique os logs e configurações."
    echo "   Execute: sudo docker-compose logs"
fi

echo ""
echo "🔧 Comandos úteis:"
echo "   Ver logs: sudo docker-compose logs -f"
echo "   Status: sudo docker-compose ps"
echo "   Reiniciar: sudo docker-compose restart"
echo "   Deploy completo: ./deploy-ubuntu-ec2.sh deploy" 