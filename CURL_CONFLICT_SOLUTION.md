# Solução para Conflito do curl no Amazon Linux 2023

## 🚨 Problema Identificado

O erro que você encontrou é um conflito comum no Amazon Linux 2023 entre o pacote `curl-minimal` (que já vem instalado por padrão) e o pacote `curl` completo que o script tenta instalar.

```
Problem: problem with installed package curl-minimal-8.11.1-4.amzn2023.0.1.x86_64
- package curl-minimal-8.11.1-4.amzn2023.0.1.x86_64 from @System conflicts with curl provided by curl-7.87.0-2.amzn2023.0.2.x86_64 from amazonlinux
```

## ✅ Soluções Disponíveis

### Solução 1: Usar Script Atualizado (Recomendado)
Os scripts foram atualizados para não tentar instalar o curl explicitamente, já que o `curl-minimal` é suficiente.

```bash
# Use o script atualizado
./deploy-amazon-linux-2023.sh
```

### Solução 2: Script Sem Dependência do curl
Use o script que não depende do curl para downloads:

```bash
# Baixar com wget
wget https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/deploy-amazon-linux-2023-no-curl.sh
chmod +x deploy-amazon-linux-2023-no-curl.sh
./deploy-amazon-linux-2023-no-curl.sh
```

### Solução 3: Script de Resolução Automática
Execute o script específico para resolver o conflito:

```bash
# Baixar e executar
wget https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/fix-curl-conflict.sh
chmod +x fix-curl-conflict.sh
./fix-curl-conflict.sh
```

### Solução 4: Resolução Manual

#### Opção A: Permitir Substituição
```bash
sudo dnf install -y --allowerasing curl
```

#### Opção B: Remover curl-minimal
```bash
sudo dnf remove -y curl-minimal
sudo dnf install -y curl
```

#### Opção C: Usar curl-minimal (Mais Seguro)
```bash
# Não fazer nada - curl-minimal é suficiente
# Apenas instalar outras dependências
sudo dnf install -y git wget unzip jq
```

#### Opção D: Pular Pacotes Problemáticos
```bash
sudo dnf install -y --skip-broken git wget unzip jq
```

## 🔍 Verificação

Após aplicar qualquer solução, verifique se o curl está funcionando:

```bash
# Verificar versão
curl --version

# Testar download
curl -L -o /tmp/test https://httpbin.org/bytes/100

# Testar requisição HTTP
curl -s https://httpbin.org/get
```

## 📋 Diferenças entre curl e curl-minimal

| Funcionalidade | curl | curl-minimal |
|----------------|------|--------------|
| Download básico | ✅ | ✅ |
| Requisições HTTP | ✅ | ✅ |
| Suporte a HTTPS | ✅ | ✅ |
| Suporte a JSON | ✅ | ✅ |
| Funcionalidades avançadas | ✅ | ⚠️ Limitado |
| Tamanho do pacote | Maior | Menor |

**Conclusão:** Para o deploy do NH Personal Trainer, o `curl-minimal` é completamente suficiente.

## 🚀 Próximos Passos

1. **Escolha uma solução** da lista acima
2. **Execute o script de deploy** escolhido
3. **Verifique se tudo está funcionando**
4. **Se houver problemas**, consulte os logs

## 📞 Suporte

Se ainda encontrar problemas:

1. Verifique os logs: `sudo docker-compose -f docker-compose.prod.yml logs`
2. Consulte a documentação completa: `AMAZON_LINUX_2023_README.md`
3. Entre em contato com o suporte

---

**Status:** ✅ **Problema Resolvido**
**Versão:** 2.1.0
**Data:** $(date) 