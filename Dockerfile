# The Flutter web app
FROM debian:trixie-slim AS frontend
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /frontend
# The Flutter version lives in frontend/.fvmrc, which CI reads as well
COPY frontend/.fvmrc ./
RUN git clone --quiet --depth 1 --branch "$(sed -n 's/.*"flutter": *"\([^"]*\)".*/\1/p' .fvmrc)" \
        https://github.com/flutter/flutter.git /opt/flutter \
    && /opt/flutter/bin/flutter config --no-analytics --no-cli-animations \
    && /opt/flutter/bin/flutter precache --web
ENV PATH=/opt/flutter/bin:$PATH
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get
COPY frontend/ ./
RUN flutter build web --release

# The backend, which serves the web app
FROM node:26-alpine
RUN apk add --no-cache tzdata
ENV NODE_ENV=production \
    TZ=Europe/Brussels \
    PORT=3000 \
    DB_PATH=/data/database.db
WORKDIR /app
COPY backend/package.json backend/package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY backend/src ./src
COPY --from=frontend /frontend/build/web ./public
RUN mkdir /data && chown node:node /data
USER node
VOLUME /data
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s CMD wget -qO /dev/null "http://127.0.0.1:$PORT/health" || exit 1
CMD ["node", "src/server.ts"]
