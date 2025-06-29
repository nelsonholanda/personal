#!/bin/bash

# Script para configurar IP público manualmente
echo "🌐 Configuração Manual do IP Público da EC2"
echo "==========================================="
echo ""

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Execute este script no diretório raiz do projeto (onde está o docker-compose.yml)"
    exit 1
fi

# Solicitar IP ao usuário
read -p "Digite o IP público da sua instância EC2: " EC2_IP

if [ -z "$EC2_IP" ]; then
    echo "❌ IP não pode estar vazio"
    exit 1
fi

# Validar formato do IP
if [[ ! $EC2_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [ "$EC2_IP" != "localhost" ]; then
    echo "❌ Formato de IP inválido: $EC2_IP"
    exit 1
fi

echo ""
echo "✅ IP válido: $EC2_IP"

# Confirmar com o usuário
read -p "Confirmar configuração do IP: $EC2_IP? (s/n): " CONFIRM_IP
if [[ ! $CONFIRM_IP =~ ^[Ss]$ ]]; then
    echo "❌ Configuração cancelada"
    exit 1
fi

# Configurar no .env do frontend
echo "⚙️ Configurando REACT_APP_API_URL no frontend..."
cd frontend

# Criar .env se não existir
if [ ! -f .env ]; then
    cp ../env.example .env 2>/dev/null || touch .env
fi

# Atualizar ou adicionar REACT_APP_API_URL
if grep -q '^REACT_APP_API_URL=' .env; then
    # Atualizar linha existente
    sed -i "s|^REACT_APP_API_URL=.*|REACT_APP_API_URL=http://$EC2_IP:3001/api|g" .env
else
    # Adicionar nova linha
    echo "REACT_APP_API_URL=http://$EC2_IP:3001/api" >> .env
fi

# Verificar se foi configurado corretamente
if grep -q "REACT_APP_API_URL=http://$EC2_IP:3001/api" .env; then
    echo "✅ REACT_APP_API_URL configurado: http://$EC2_IP:3001/api"
else
    echo "❌ Falha ao configurar REACT_APP_API_URL"
    exit 1
fi

cd ..

# Salvar IP para uso posterior
echo "$EC2_IP" > .ec2_ip
echo "✅ IP da EC2 salvo para uso posterior"

echo ""
echo "🎉 Configuração concluída!"
echo "📋 Resumo:"
echo "   • IP configurado: $EC2_IP"
echo "   • Frontend API URL: http://$EC2_IP:3001/api"
echo "   • URLs da aplicação:"
echo "     - Frontend: http://$EC2_IP:3000"
echo "     - Backend: http://$EC2_IP:3001"
echo ""
echo "💡 Para fazer deploy completo, execute: ./deploy-ubuntu-ec2.sh deploy" 