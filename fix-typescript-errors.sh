#!/bin/bash

# Script para corrigir erros de TypeScript automaticamente
# Adiciona return statements onde necessário

echo "🔧 Corrigindo erros de TypeScript..."

# Função para adicionar return statements nos catch blocks
fix_catch_blocks() {
    local file="$1"
    echo "Corrigindo $file..."
    
    # Adicionar return antes de res.status nos catch blocks
    sed -i 's/\([[:space:]]*\)res\.status(\([0-9]*\)).json(/\1return res.status(\2).json(/g' "$file"
    
    # Adicionar return antes de res.json nos catch blocks
    sed -i 's/\([[:space:]]*\)res\.json(/\1return res.json(/g' "$file"
}

# Corrigir todos os arquivos com erros
fix_catch_blocks "backend/src/controllers/authController.ts"
fix_catch_blocks "backend/src/controllers/clientManagementController.ts"
fix_catch_blocks "backend/src/controllers/passwordController.ts"
fix_catch_blocks "backend/src/controllers/paymentController.ts"
fix_catch_blocks "backend/src/middleware/adminAuth.ts"
fix_catch_blocks "backend/src/middleware/auth.ts"

echo "✅ Correções aplicadas!"
echo "🔍 Testando build..."
cd backend && npm run build 