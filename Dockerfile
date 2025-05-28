# Stage 1: Build Flutter web app
FROM ghcr.io/cirruslabs/flutter:3.29.2 AS flutter-build
WORKDIR /app/frontend
COPY frontend/ .
RUN flutter pub get && flutter build web

# Stage 2: Build Node.js backend
FROM node:18-alpine
WORKDIR /app

# Install mDNS resolution tools
RUN apk add --no-cache avahi nss-mdns libc6-compat

# Fix nsswitch.conf for mDNS support
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' > /etc/nsswitch.conf

# Create data directory
RUN mkdir -p /data && chown node:node /data

# Copy built files
COPY --from=flutter-build /app/frontend/build/web ./backend/public
COPY backend/ ./backend/

# Set environment
ENV NODE_ENV=production
ENV DB_PATH=/data/database.db
ENV PORT=3000
WORKDIR /app/backend

# Install dependencies
RUN npm install --omit=dev

# Run as non-root user
USER node

EXPOSE 3000
CMD ["node", "server.js"]

# Volume declaration
VOLUME /data
