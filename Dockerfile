# Stage 1: Build Flutter web app
FROM ghcr.io/cirruslabs/flutter:3.32.0 AS flutter-build
WORKDIR /app/frontend
COPY frontend/ .
RUN flutter pub get && flutter build web

# Stage 2: Build Node.js backend
FROM node:22-slim
WORKDIR /app

RUN apt update && \
    apt install -y sudo && \
    echo "node:nodepass" | chpasswd && \
    adduser node sudo

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
