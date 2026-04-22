# Build Stage
FROM --platform=$BUILDPLATFORM golang:1.26.1-alpine AS builder

ARG TARGETOS
ARG TARGETARCH

# CGO braucht gcc
RUN apk add --no-cache gcc musl-dev

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# CGO_ENABLED=1 wegen SQLite
RUN CGO_ENABLED=1 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w" \
    -o server ./cmd/api

# Runtime Stage - braucht musl wegen CGO
FROM alpine:3.19

RUN apk add --no-cache libc6-compat

WORKDIR /app

# Ordner erstellen
RUN mkdir -p /app/data && \
    mkdir -p /app/uploads && \
    chown -R nobody:nobody /app/data && \
    chown -R nobody:nobody /app/uploads

COPY --from=builder /app/server /app/server

USER nobody:nobody

ENTRYPOINT ["/app/server"]