# Stage 1: Build Flutter web app
FROM ghcr.io/cirruslabs/flutter:3.29.2 AS flutter-build
WORKDIR /app/frontend
COPY frontend/ .
RUN flutter pub get && flutter build web

# Stage 2: Build Node.js backend with mDNS support
FROM node:18-slim

# Install mDNS resolution tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libnss-mdns avahi-daemon avahi-utils && \
    rm -rf /var/lib/apt/lists/*

# Fix nsswitch.conf for mDNS support
RUN sed -i 's/^hosts:.*/hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4/' /etc/nsswitch.conf

WORKDIR /app

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
