# Use the official Bun image as the base
FROM oven/bun:1-slim AS base
WORKDIR /usr/src/app

# Stage 1: Install dependencies for development and production
FROM base AS install
RUN mkdir -p /temp/dev
COPY package.json bun.lockb /temp/dev/
RUN cd /temp/dev && bun install --frozen-lockfile

# Stage 2: Install only production dependencies
FROM base AS prod-deps
RUN mkdir -p /temp/prod
COPY package.json bun.lockb /temp/prod/
RUN cd /temp/prod && bun install --frozen-lockfile --production

# Stage 3: Prerelease - Copy dependencies and build the application
FROM base AS prerelease
COPY --from=install /temp/dev/node_modules node_modules
COPY . .

# Build the Next.js app for production
ENV NODE_ENV=production
RUN bun run build

# Stage 4: Final release image
FROM oven/bun:1-slim AS release
WORKDIR /usr/src/app

# Copy production dependencies and only essential files
COPY --from=prod-deps /temp/prod/node_modules ./node_modules
COPY --from=prerelease /usr/src/app/.next ./.next
COPY --from=prerelease /usr/src/app/public ./public
COPY --from=prerelease /usr/src/app/package.json ./package.json

# Use a non-root user for security
USER bun

# Expose port 3000 and run the application
EXPOSE 3000
CMD ["bun", "run", "start"]
