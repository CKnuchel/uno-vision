# UNO Vision

A mobile-first UNO score tracking app with ML-powered card detection. Scan your cards, track scores, and crown the winner!

## Features

- **Card Scanning** - Use your camera to detect UNO cards and automatically calculate points
- **Real-time Multiplayer** - Create or join parties with friends via WebSocket sync
- **Cross-Platform** - Works on Android and Web (PWA)
- **Offline Support** - Local storage for seamless gameplay
- **Beautiful UI** - Modern design with dark mode support

## Tech Stack

| Component | Technology |
|-----------|------------|
| **Mobile/Web App** | Flutter, Riverpod |
| **ML Model** | TensorFlow Lite (YOLOv8) |
| **Backend** | Go, Gin, SQLite |
| **Deployment** | Docker, nginx |

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│   Go Backend    │
│  (Android/Web)  │◀────│   (REST + WS)   │
└─────────────────┘     └─────────────────┘
        │                       │
        ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│  TFLite Model   │     │     SQLite      │
│ (Card Detection)│     │   (Parties,     │
│  Android only   │     │    Scores)      │
└─────────────────┘     └─────────────────┘
```

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (3.x)
- [Go](https://golang.org/dl/) (1.21+)
- [Docker](https://docs.docker.com/get-docker/) (optional, for deployment)

### Local Development

**1. Clone the repository**
```bash
git clone https://github.com/yourusername/uno-vision.git
cd uno-vision
```

**2. Start the backend**
```bash
make dev
# or manually:
cd backend && go run cmd/api/*.go
```

**3. Configure the app**
```bash
cd app
cp lib/core/constants/api_config.example.dart lib/core/constants/api_config.dart
```

**4. Run the app**
```bash
# Android
flutter run

# Web
flutter run -d chrome
```

### Available Make Commands

```bash
# Backend
make dev              # Run backend locally
make build            # Build backend binary
make test             # Run backend tests

# Flutter App
make app-run-android  # Run on Android
make app-run-chrome   # Run in Chrome
make app-debug-apk    # Build debug APK
make app-release-apk  # Build release APK
make app-build-web    # Build web release
make app-analyze      # Run linter
make app-format       # Format code

# Docker
make up               # Start all services
make down             # Stop all services
make logs             # View logs
```

## Deployment

### Docker (Raspberry Pi / Server)

**1. Clone and configure**
```bash
git clone https://github.com/yourusername/uno-vision.git
cd uno-vision

# Create config with your domain
cp app/lib/core/constants/api_config.example.dart \
   app/lib/core/constants/api_config.dart

# Edit the production URLs
nano app/lib/core/constants/api_config.dart
```

**2. Update the production URLs**
```dart
const String productionApiUrl = 'https://api.your-domain.com/api/v1';
const String productionWsUrl = 'wss://api.your-domain.com/api/v1';
```

**3. Start the containers**
```bash
docker compose up -d --build
```

**4. Configure your reverse proxy / Cloudflare Tunnel**

| Service | Internal Port | Domain |
|---------|---------------|--------|
| Web App | 3000 | `uno-vision.your-domain.com` |
| API | 3001 | `api.uno-vision.your-domain.com` |

### Manual APK Installation

Download the APK from [Releases](https://github.com/yourusername/uno-vision/releases) or build it yourself:

```bash
make app-release-apk
# Output: app/build/app/outputs/flutter-apk/app-release.apk
```

## API Documentation

See [backend/README.md](backend/README.md) for full API documentation.

### Quick Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/party` | POST | Create a new party |
| `/api/v1/party/join/:code` | POST | Join a party |
| `/api/v1/party/:id` | GET | Get party details |
| `/api/v1/party/:id/start` | POST | Start the game |
| `/api/v1/party/:id/round/winner` | POST | Report round win |
| `/api/v1/party/:id/round/score` | POST | Submit score |
| `/api/v1/party/:id/ws` | WS | Real-time updates |

## Project Structure

```
uno-vision/
├── app/                    # Flutter application
│   ├── lib/
│   │   ├── core/           # Theme, constants, networking
│   │   ├── models/         # Data models
│   │   ├── providers/      # Riverpod providers
│   │   ├── screens/        # UI screens
│   │   ├── services/       # Business logic
│   │   └── widgets/        # Reusable components
│   ├── assets/
│   │   └── models/         # TFLite model files
│   └── Dockerfile
├── backend/                # Go API server
│   ├── cmd/api/            # Entry point
│   ├── internal/           # Business logic
│   └── Dockerfile
├── ml/                     # ML training (not in repo)
├── docker-compose.yml
├── Makefile
└── README.md
```

## Card Detection

The app uses a custom-trained YOLOv8 model to detect UNO cards:

- **15 Classes**: Numbers (0-9), +2, +4, Reverse, Skip, Wild
- **Input**: 416x416 RGB image
- **Output**: Bounding boxes with class labels and confidence scores

> Note: Card detection only works on Android. On Web, cards must be entered manually.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ and too many UNO +4 cards
