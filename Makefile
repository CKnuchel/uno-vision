.PHONY: dev build up up-d down logs test clean tidy \
        app-get app-clean app-analyze app-format app-test \
        app-run-android app-run-web app-run-chrome \
        app-debug-apk app-release-apk app-build-web app-build-appbundle \
        app-install

# ==============================================================================
# Backend
# ==============================================================================

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

# ==============================================================================
# Flutter App - Setup & Maintenance
# ==============================================================================

app-get:
	cd app && flutter pub get

app-clean:
	cd app && flutter clean && flutter pub get

app-analyze:
	cd app && flutter analyze

app-format:
	cd app && dart format lib/ test/

app-test:
	cd app && flutter test

# ==============================================================================
# Flutter App - Run (Debug)
# ==============================================================================

app-run-android:
	cd app && flutter run

app-run-web:
	cd app && flutter run -d web-server --web-port=8080

app-run-chrome:
	cd app && flutter run -d chrome

# ==============================================================================
# Flutter App - Build Debug
# ==============================================================================

app-debug-apk:
	cd app && flutter build apk --debug
	@echo "Debug APK: app/build/app/outputs/flutter-apk/app-debug.apk"

app-debug-web:
	cd app && flutter build web --profile
	@echo "Debug Web: app/build/web/"

# ==============================================================================
# Flutter App - Build Release
# ==============================================================================

app-release-apk:
	cd app && flutter build apk --release
	@echo "Release APK: app/build/app/outputs/flutter-apk/app-release.apk"

app-build-appbundle:
	cd app && flutter build appbundle --release
	@echo "App Bundle: app/build/app/outputs/bundle/release/app-release.aab"

app-build-web:
	cd app && flutter build web --release
	@echo "Release Web: app/build/web/"

# ==============================================================================
# Flutter App - Install on Device
# ==============================================================================

app-install:
	cd app && flutter install

# ==============================================================================
# Full Project
# ==============================================================================

all-clean: clean app-clean

all-test: test app-test
