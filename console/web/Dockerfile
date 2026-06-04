# ── build the Angular app ────────────────────────────────────
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npm run build

# ── serve via nginx, reverse-proxying /api to the console API ─
FROM nginx:1.27-alpine
# Angular's application builder emits the browser bundle under browser/.
COPY --from=build /app/dist/console/browser /usr/share/nginx/html
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
# Where the SPA's /api/* calls are proxied. console-api:8090 resolves on both
# the docker-compose network and in-cluster (Service name). Override as needed.
ENV API_UPSTREAM=console-api:8090
EXPOSE 80
