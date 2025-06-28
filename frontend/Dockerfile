# Build stage
FROM node:18-alpine AS build

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM node:18-alpine

# Install serve for static file serving
RUN npm install -g serve

# Copy built app from build stage
COPY --from=build /app/build /app/build

# Set working directory
WORKDIR /app

# Expose port
EXPOSE 80

# Start serve
CMD ["serve", "-s", "build", "-l", "80"] 