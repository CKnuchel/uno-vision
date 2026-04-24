# Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get

COPY . .

# Ensure api_config.dart exists (copy from example if missing)
RUN if [ ! -f lib/core/constants/api_config.dart ]; then \
      echo "WARNING: api_config.dart not found, copying from example..."; \
      cp lib/core/constants/api_config.example.dart lib/core/constants/api_config.dart; \
    fi

RUN flutter build web --release

# Production stage
FROM nginx:alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
