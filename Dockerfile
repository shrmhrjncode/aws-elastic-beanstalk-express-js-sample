# Stage 1: Install dependencies and prepare the application
FROM node:16-bookworm-slim AS build

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev && \
    npm cache clean --force

COPY app.js ./


# Stage 2: Production runtime
FROM node:16-bookworm-slim AS runtime

WORKDIR /app

# Update Debian packages with the latest available security updates
RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package*.json ./
COPY --from=build /app/app.js ./

# npm is not required to run the production application
RUN npm uninstall -g npm || true

EXPOSE 8080

CMD ["node", "app.js"]
