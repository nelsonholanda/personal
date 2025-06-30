# Dockerfile único para NH Gestão de Alunos
FROM node:18-alpine

# Instalar dependências do sistema
RUN apk add --no-cache \
    openssl \
    && rm -rf /var/cache/apk/*

# Definir diretório de trabalho
WORKDIR /app

# Copiar package.json do backend
COPY backend/package*.json ./

# Instalar dependências do backend
RUN npm install

# Copiar package.json do frontend
COPY frontend/package*.json ./frontend/

# Instalar dependências do frontend
RUN cd frontend && npm install

# Copiar código do backend
COPY backend/ ./

# Gerar cliente Prisma
RUN npx prisma generate

# Build do backend
RUN npm run build

# Copiar código do frontend
COPY frontend/ ./frontend/

# Build do frontend
RUN cd frontend && npm run build

# Expor porta
EXPOSE 3000

# Comando para iniciar a aplicação
CMD ["node", "dist/index.js"] 