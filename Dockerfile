# Use Bun base image
FROM oven/bun:alpine AS build

# Set the working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package.json bun.lockb ./
RUN bun install

# Copy the rest of the app files
COPY . .

# Set environment variable for production mode
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Build the Next.js app
RUN bun run build

# Use a new stage for the production runtime to keep the image small
FROM oven/bun:alpine AS runner

# Set the working directory
WORKDIR /app

# Copy only the built output and necessary files for running the server
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/package.json .
COPY --from=build /app/node_modules ./node_modules

# Expose port 3000 to the host
EXPOSE 3000

# Start the Next.js app in production mode
CMD ["bun", "run", "start"]
