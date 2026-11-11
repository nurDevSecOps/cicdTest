# shortly, served by its own nginx - one image, one container.
# Stage 1 builds + tests the app; stage 2 is the app PLUS nginx in front of it.
# The TLS cert is generated at startup (start.sh), never baked into a layer.

# ---- stage 1: build + test ----
FROM node:26-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build && npm test

# ---- stage 2: run (app + nginx) ----
FROM node:26-alpine
ENV NODE_ENV=production
# nginx = the web server; openssl = the startup cert; upgrade patches the base for the gate
RUN apk --no-cache -U upgrade && apk add --no-cache nginx openssl
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
COPY public ./public
RUN rm -rf /usr/local/lib/node_modules/npm
# your web-server config + the launcher that runs node and nginx together
COPY nginx.conf /etc/nginx/http.d/default.conf
COPY start.sh /usr/local/bin/start.sh
RUN sed -i 's/\r$//' /usr/local/bin/start.sh && chmod +x /usr/local/bin/start.sh \
 && mkdir -p /app/data
EXPOSE 443
# health = the app answering on its loopback port inside the container
HEALTHCHECK --interval=10s --timeout=3s --retries=6 \
  CMD wget -qO- http://127.0.0.1:3000/healthz || exit 1
ARG GIT_SHA=dev
ENV GIT_SHA=$GIT_SHA
CMD ["/usr/local/bin/start.sh"]
