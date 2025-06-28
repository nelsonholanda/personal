FROM node:18-alpine

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
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

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