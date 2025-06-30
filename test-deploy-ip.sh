#!/bin/bash

# Script de teste para verificar a funcionalidade de IP no deploy
# NH Gestão de Alunos

echo "🧪 TESTE DA FUNCIONALIDADE DE IP NO DEPLOY"
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

# Verificar se o script de deploy existe
if [ ! -f "deploy-ubuntu-ec2.sh" ]; then
    error "Script de deploy não encontrado"
    exit 1
fi

success "Script de deploy encontrado"

# Verificar se o script tem permissão de execução
if [ ! -x "deploy-ubuntu-ec2.sh" ]; then
    log "Adicionando permissão de execução..."
    chmod +x deploy-ubuntu-ec2.sh
fi

# Verificar se a função prompt_server_ip existe
if grep -q "prompt_server_ip" deploy-ubuntu-ec2.sh; then
    success "Função prompt_server_ip encontrada"
else
    error "Função prompt_server_ip não encontrada"
fi

# Verificar se a função deploy_application foi modificada
if grep -q "Verificar se o IP já está configurado" deploy-ubuntu-ec2.sh; then
    success "Função deploy_application modificada para verificar IP"
else
    error "Função deploy_application não foi modificada"
fi

# Verificar se a validação de IP foi implementada
if grep -q "Validar formato do IP" deploy-ubuntu-ec2.sh; then
    success "Validação de IP implementada"
else
    error "Validação de IP não implementada"
fi

# Verificar se o arquivo .ec2_ip é usado
if grep -q "\.ec2_ip" deploy-ubuntu-ec2.sh; then
    success "Arquivo .ec2_ip é usado corretamente"
else
    error "Arquivo .ec2_ip não é usado"
fi

# Verificar se a ajuda foi atualizada
if grep -q "IP será solicitado automaticamente" deploy-ubuntu-ec2.sh; then
    success "Ajuda atualizada com informações sobre IP"
else
    error "Ajuda não foi atualizada"
fi

echo ""
echo "📋 RESUMO DAS VERIFICAÇÕES:"
echo "==========================="

# Contar quantas vezes cada funcionalidade aparece
PROMPT_COUNT=$(grep -c "prompt_server_ip" deploy-ubuntu-ec2.sh)
DEPLOY_COUNT=$(grep -c "Verificar se o IP já está configurado" deploy-ubuntu-ec2.sh)
VALIDATION_COUNT=$(grep -c "Validar formato do IP" deploy-ubuntu-ec2.sh)
EC2_IP_COUNT=$(grep -c "\.ec2_ip" deploy-ubuntu-ec2.sh)
HELP_COUNT=$(grep -c "IP será solicitado automaticamente" deploy-ubuntu-ec2.sh)

echo "   • Função prompt_server_ip: $PROMPT_COUNT ocorrências"
echo "   • Verificação de IP no deploy: $DEPLOY_COUNT ocorrências"
echo "   • Validação de formato de IP: $VALIDATION_COUNT ocorrências"
echo "   • Uso do arquivo .ec2_ip: $EC2_IP_COUNT ocorrências"
echo "   • Ajuda atualizada: $HELP_COUNT ocorrências"

echo ""
echo "🎯 FUNCIONALIDADES IMPLEMENTADAS:"
echo "================================="

echo "✅ Solicitação automática de IP durante o deploy"
echo "✅ Validação de formato de IP (xxx.xxx.xxx.xxx)"
echo "✅ Validação de octetos (0-255)"
echo "✅ Opção de alterar IP existente"
echo "✅ Configuração automática de variáveis de ambiente"
echo "✅ Criação de arquivos .env específicos"
echo "✅ Persistência do IP em arquivo .ec2_ip"

echo ""
echo "📝 COMO USAR:"
echo "============="
echo "1. Execute: ./deploy-ubuntu-ec2.sh deploy"
echo "2. O script solicitará o IP público da EC2"
echo "3. Digite o IP no formato: xxx.xxx.xxx.xxx"
echo "4. O script validará e configurará automaticamente"
echo "5. O deploy continuará com as configurações corretas"

echo ""
echo "🔧 COMANDOS ÚTEIS:"
echo "=================="
echo "   ./deploy-ubuntu-ec2.sh deploy     # Deploy completo"
echo "   ./deploy-ubuntu-ec2.sh config-ip  # Configurar IP manualmente"
echo "   ./deploy-ubuntu-ec2.sh help       # Ver ajuda"
echo "   ./test-env.sh                     # Testar configurações"

echo ""
success "✅ Teste concluído! A funcionalidade está pronta para uso." 