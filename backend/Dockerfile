# Multi-stage build for production
FROM node:22-alpine AS builder

WORKDIR /app

# Install OpenSSL and other required packages for Prisma
RUN apk add --no-cache openssl libc6-compat

# Copy package files
COPY package.json ./
COPY yarn.lock ./
COPY tsconfig.json ./

# Install all dependencies (including dev dependencies for build)
RUN yarn install --frozen-lockfile

# Copy source code
COPY src/ ./src/
COPY prisma/ ./prisma/

# Generate Prisma client
RUN npx prisma generate

# Build TypeScript
RUN yarn build

# Install only production dependencies for final image
RUN yarn install --production --frozen-lockfile && yarn cache clean

# Production stage
FROM node:22-alpine AS production

WORKDIR /app

# Install dumb-init and OpenSSL for proper signal handling and Prisma compatibility
RUN apk add --no-cache dumb-init openssl libc6-compat

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S convooy -u 1001

# Copy built application
COPY --from=builder --chown=convooy:nodejs /app/dist ./dist
COPY --from=builder --chown=convooy:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=convooy:nodejs /app/package.json ./
COPY --from=builder --chown=convooy:nodejs /app/yarn.lock ./yarn.lock
COPY --from=builder --chown=convooy:nodejs /app/prisma ./prisma

# Create logs directory
RUN mkdir -p logs && chown convooy:nodejs logs

USER convooy

EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/api/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

CMD ["yarn", "start"]
