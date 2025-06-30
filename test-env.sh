#!/bin/bash

# Script de teste para verificar configurações dos arquivos .env
# NH Gestão de Alunos

echo "🔍 TESTE DE CONFIGURAÇÕES DOS ARQUIVOS .ENV"
echo "=========================================="

# Funções de log
log() {
    echo "📋 $1"
}

success() {
    echo "✅ $1"
}

error() {
    echo "❌ $1"
}

warning() {
    echo "⚠️ $1"
}

# Verificar se os arquivos .env existem
log "Verificando existência dos arquivos .env..."

if [ -f "backend/.env" ]; then
    success "Backend .env encontrado"
    BACKEND_SIZE=$(wc -c < backend/.env)
    echo "   Tamanho: ${BACKEND_SIZE} bytes"
else
    error "Backend .env não encontrado"
fi

if [ -f "frontend/.env" ]; then
    success "Frontend .env encontrado"
    FRONTEND_SIZE=$(wc -c < frontend/.env)
    echo "   Tamanho: ${FRONTEND_SIZE} bytes"
else
    error "Frontend .env não encontrado"
fi

if [ -f ".env" ]; then
    success "Arquivo .env principal encontrado"
    MAIN_SIZE=$(wc -c < .env)
    echo "   Tamanho: ${MAIN_SIZE} bytes"
else
    warning "Arquivo .env principal não encontrado (opcional)"
fi

echo ""

# Verificar variáveis importantes no backend
log "Verificando variáveis importantes no backend..."

if [ -f "backend/.env" ]; then
    # Verificar DATABASE_URL
    if grep -q "DATABASE_URL=" backend/.env; then
        success "DATABASE_URL configurada"
    else
        error "DATABASE_URL não encontrada"
    fi
    
    # Verificar JWT_SECRET
    if grep -q "JWT_ACCESS_TOKEN_SECRET=" backend/.env; then
        success "JWT_ACCESS_TOKEN_SECRET configurada"
    else
        error "JWT_ACCESS_TOKEN_SECRET não encontrada"
    fi
    
    # Verificar ENCRYPTION_KEY
    if grep -q "ENCRYPTION_KEY=" backend/.env; then
        success "ENCRYPTION_KEY configurada"
    else
        error "ENCRYPTION_KEY não encontrada"
    fi
    
    # Verificar NODE_ENV
    if grep -q "NODE_ENV=production" backend/.env; then
        success "NODE_ENV configurado para produção"
    else
        warning "NODE_ENV não configurado para produção"
    fi
fi

echo ""

# Verificar variáveis importantes no frontend
log "Verificando variáveis importantes no frontend..."

if [ -f "frontend/.env" ]; then
    # Verificar REACT_APP_API_URL
    if grep -q "REACT_APP_API_URL=" frontend/.env; then
        success "REACT_APP_API_URL configurada"
        API_URL=$(grep "REACT_APP_API_URL=" frontend/.env | cut -d'=' -f2)
        echo "   URL: $API_URL"
    else
        error "REACT_APP_API_URL não encontrada"
    fi
    
    # Verificar REACT_APP_ENV
    if grep -q "REACT_APP_ENV=production" frontend/.env; then
        success "REACT_APP_ENV configurado para produção"
    else
        warning "REACT_APP_ENV não configurado para produção"
    fi
fi

echo ""

# Verificar docker-compose.yml
log "Verificando configuração do Docker Compose..."

if [ -f "docker-compose.yml" ]; then
    if grep -q "env_file:" docker-compose.yml; then
        success "Docker Compose configurado para usar env_file"
    else
        error "Docker Compose não configurado para usar env_file"
    fi
else
    error "docker-compose.yml não encontrado"
fi

echo ""

# Verificar Dockerfile
log "Verificando configuração do Dockerfile..."

if [ -f "Dockerfile" ]; then
    if grep -q "COPY.*\.env" Dockerfile; then
        success "Dockerfile configurado para copiar arquivos .env"
    else
        error "Dockerfile não configurado para copiar arquivos .env"
    fi
else
    error "Dockerfile não encontrado"
fi

echo ""

# Verificar script de deploy
log "Verificando script de deploy..."

if [ -f "deploy-ubuntu-ec2.sh" ]; then
    if grep -q "backend/\.env" deploy-ubuntu-ec2.sh; then
        success "Script de deploy configurado para criar backend/.env"
    else
        error "Script de deploy não configurado para criar backend/.env"
    fi
    
    if grep -q "frontend/\.env" deploy-ubuntu-ec2.sh; then
        success "Script de deploy configurado para criar frontend/.env"
    else
        error "Script de deploy não configurado para criar frontend/.env"
    fi
else
    error "Script de deploy não encontrado"
fi

echo ""
echo "🎯 RECOMENDAÇÕES:"
echo "================="

# Verificar se as URLs estão configuradas corretamente
if [ -f "frontend/.env" ]; then
    API_URL=$(grep "REACT_APP_API_URL=" frontend/.env | cut -d'=' -f2)
    if [[ "$API_URL" == *"localhost"* ]]; then
        warning "REACT_APP_API_URL ainda aponta para localhost"
        echo "   Considere atualizar para o IP do servidor em produção"
    fi
fi

if [ -f "backend/.env" ]; then
    FRONTEND_URL=$(grep "FRONTEND_URL=" backend/.env | cut -d'=' -f2)
    if [[ "$FRONTEND_URL" == *"localhost"* ]]; then
        warning "FRONTEND_URL ainda aponta para localhost"
        echo "   Considere atualizar para o IP do servidor em produção"
    fi
fi

echo ""
echo "✅ Teste concluído!"
echo "📋 Para aplicar as configurações em produção, execute:"
echo "   ./deploy-ubuntu-ec2.sh config-ip"
echo "   ./deploy-ubuntu-ec2.sh deploy" 