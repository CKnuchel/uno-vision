.PHONY: dev build up up-d down logs test clean tidy

dev:
	cd backend && go run cmd/api/*.go

build:
	cd backend && go build -o bin/api cmd/api/*.go

up:
	docker compose up --build

up-d:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f

test:
	cd backend && go test ./...

clean:
	cd backend && rm -rf bin/
	docker compose down -v

tidy:
	cd backend && go mod tidy
