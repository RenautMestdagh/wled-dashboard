# Stage 1: Build Flutter web app
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS flutter-build
WORKDIR /app/frontend
COPY frontend/ .
RUN flutter pub get && flutter build web

# Stage 2: Build Node.js backend
FROM node:26-alpine
WORKDIR /app

# Install timezone data
RUN apk add --no-cache tzdata

# Set timezone to Brussels
ENV TZ=Europe/Brussels

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

# Install dependencies (better-sqlite3 13 ships no prebuilt binaries: compile it, then drop the compiler again)
RUN apk add --no-cache --virtual .build-deps python3 make g++ && \
    npm install --omit=dev && \
    apk del .build-deps

# Run as non-root user
USER node

EXPOSE 3000
CMD ["node", "server.js"]

# Volume declaration
VOLUME /data
