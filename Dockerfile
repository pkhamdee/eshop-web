FROM node:24-alpine@sha256:a34ab6d7f6f4813f4d0c5469d74685604b962fbdbf5793a7bc7b4998ecb867c8 AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# Caddy, not NGINX (ADR-0002). Runs as non-root on 8080.
FROM caddy:2.11.7-alpine@sha256:e70b164da81ef698b3ad19af799ea6086ce6d9e48ed4079eb9fe26f6fbf14ee5
# Pick up Alpine security fixes released after the base image was built, and strip the
# cap_net_bind_service file capability from caddy: we listen on 8080, and with it the binary
# cannot exec in a pod that drops ALL capabilities ("operation not permitted").
RUN apk upgrade --no-cache \
    && apk add --no-cache --virtual .setcap libcap-setcap \
    && setcap -r /usr/bin/caddy \
    && apk del .setcap
ENV XDG_CONFIG_HOME=/tmp/config XDG_DATA_HOME=/tmp/data
COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/dist /srv
USER 65532:65532
EXPOSE 8080
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
