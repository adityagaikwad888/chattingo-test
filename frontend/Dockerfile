# Stage 1: Dependencies installation
FROM node:18-alpine AS dependencies

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production --silent && \
    npm cache clean --force


# Stage 2: Build application
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --silent

COPY . .
RUN npm run build && \
    rm -rf node_modules && \
    npm cache clean --force


# Stage 3: Production runtime
FROM nginx:alpine AS production

RUN apk add --no-cache curl

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build /usr/share/nginx/html

RUN chmod -R 755 /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
