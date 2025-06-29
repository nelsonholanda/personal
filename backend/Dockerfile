FROM node:18-slim

# Install system dependencies including OpenSSL
RUN apt-get update && apt-get install -y \
    openssl \
    libssl1.1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
RUN npm ci

# Copy source code
COPY . .

# Generate Prisma client
RUN npx prisma generate

# Build the application
RUN npm run build

# Verify that the build was successful
RUN ls -la dist/ && test -f dist/index.js

# Remove devDependencies and keep only production dependencies
RUN npm prune --production

# Create non-root user
RUN groupadd -r nodejs && useradd -r -g nodejs nodejs

# Change ownership of the app directory
RUN chown -R nodejs:nodejs /app
USER nodejs

# Expose port
EXPOSE 3001

# Health check (more tolerant)
HEALTHCHECK --interval=60s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -f http://localhost:3001/health || exit 1

# Start the application
CMD ["npm", "start"] 