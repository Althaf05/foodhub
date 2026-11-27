# Stage 1: build the static files
FROM node:26-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build

# Stage 2: Alpine's own nginx, patched, running as non-root
FROM alpine:3.24
RUN apk add --no-cache nginx \
 && mkdir -p /run/nginx /var/lib/nginx/tmp /var/log/nginx \
 && chown -R nginx:nginx /run/nginx /var/lib/nginx /var/log/nginx
COPY nginx.conf /etc/nginx/http.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
USER nginx
EXPOSE 8080
CMD ["nginx", "-g", "daemon off; pid /tmp/nginx.pid; error_log /dev/stderr;"]
