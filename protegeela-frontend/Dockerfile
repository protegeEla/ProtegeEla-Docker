FROM debian:bookworm-slim

ARG FLUTTER_VERSION=3.47.5
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git curl unzip xz-utils zip libglu1-mesa nginx \
    && git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git "${FLUTTER_HOME}" \
    && flutter config --enable-web \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 3000
CMD ["sh", "-c", "flutter pub get && flutter build web --release --no-wasm-dry-run --dart-define=API_BASE_URL=${API_BASE_URL:-http://localhost:8080/api} && rm -rf /usr/share/nginx/html/* && cp -a build/web/. /usr/share/nginx/html/ && exec nginx -g 'daemon off;'"]
