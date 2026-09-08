# syntax=docker/dockerfile:1.7
FROM --platform=${BUILDPLATFORM} node:26-alpine AS build
WORKDIR /workspace
COPY zscaler_root.crt /usr/local/share/ca-certificates/zscaler_root.crt
RUN apk --no-check-certificate add --no-cache ca-certificates \
	&& update-ca-certificates
ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
COPY package.json package-lock.json ./
RUN npm ci
COPY angular.json tsconfig.json tsconfig.app.json tsconfig.spec.json ./
COPY public ./public
COPY src ./src
RUN npm run build

FROM nginxinc/nginx-unprivileged:1.29-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --chmod=755 docker/40-clock-config.sh /docker-entrypoint.d/40-clock-config.sh
COPY --chown=101:101 --from=build /workspace/dist/example-frontend/browser /usr/share/nginx/html
EXPOSE 8080
