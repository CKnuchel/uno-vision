# 🎴 UNO Vision – Backend

> Go REST API with WebSocket support for the UNO Vision app. Manages parties, players, rounds, and scores.

---

## 🛠️ Tech Stack

| Technology | Usage |
|---|---|
| 🐹 **Go 1.26** | Programming language |
| ⚡ **Gin** | HTTP router |
| 🗄️ **GORM** | ORM / database access |
| 🪨 **SQLite** | Database |
| 🔌 **Gorilla WebSocket** | WebSocket connections |
| 🐳 **Docker** | Containerization |

---

## 🏗️ Architecture

```
Handler → Service → Repository → DB
              ↓
             Hub (WebSocket Broadcasts)
```

| Layer | Responsibility |
|---|---|
| 🌐 **Handler** | HTTP request/response, input validation |
| ⚙️ **Service** | Business logic, calculations |
| 🗃️ **Repository** | DB operations (CRUD), no logic |
| 📡 **Hub** | Manage WebSocket connections, broadcast events |

### 📁 Project Structure

```
backend/
  cmd/
    api/
      main.go         ← Entry point, wires everything together
      server.go       ← Graceful shutdown logic
  internal/
    config/           ← Configuration via environment variables
    database/         ← DB connection + AutoMigration
    dto/              ← Request/Response structs
    errors/           ← Typed error definitions
    handlers/         ← HTTP + WebSocket handlers
    hub/              ← WebSocket hub + client
    models/           ← GORM models
    repository/       ← DB operations
    router/           ← Route definitions
    services/         ← Business logic
  Dockerfile
  go.mod
```

---

## 🎮 Game Modes

### 🏆 Classic
- The round winner collects the points of all losers
- First player to reach `target_score` **wins**

### ⛳ Golf
- Each loser collects their own points
- First player to reach `target_score` **loses**
- Player with the **fewest points** when the game ends **wins**

---

## 🔄 Game Flow

```
1. 🏠 Host creates a party       → POST /api/v1/party
2. 👥 Players join               → POST /api/v1/party/join/:code
3. 📡 Everyone connects via WS   → WS  /api/v1/party/:id/ws
4. ▶️  Host starts the game       → POST /api/v1/party/:id/start
5. 🔁 Each round:
   a. 🥇 Winner reports in        → POST /api/v1/party/:id/round/winner
   b. 📷 All others submit score  → POST /api/v1/party/:id/round/score
   c. 📢 Server broadcasts scores via WS
6. 🏁 When target_score reached  → game_over event via WS
```

---

## ⚙️ Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `8080` | HTTP server port |
| `DB_PATH` | `sqlite.db` | Path to SQLite database file |
| `UPLOAD_PATH` | `uploads/` | Path for storing card images |
| `GIN_MODE` | `debug` | Set to `release` in production |

---

## 🚀 Running Locally

### Prerequisites
- Go 1.26+
- gcc (required for SQLite/CGO)

### Start

```bash
cd backend
go run cmd/api/*.go
```

### Build

```bash
cd backend
go build -o bin/api cmd/api/*.go
./bin/api
```

---

## 🐳 Docker

### Build & Run

```bash
docker compose up --build
```

### Run in background

```bash
docker compose up -d
```

### Stop

```bash
docker compose down
```

### 💾 Volumes
| Volume | Path | Description |
|---|---|---|
| `db_data` | `/app/data` | SQLite database (persistent) |
| `uploads` | `/app/uploads` | Card images (persistent) |

---

## 📡 Deploying

```bash
# Clone repo
git clone https://github.com/CKnuchel/uno-vision.git
cd uno-vision

# Start
docker compose up -d

# Check logs
docker compose logs -f

# Stop
docker compose down
```

---

## 📖 API Reference

### 🏥 Health Check

```
GET /health
```

```json
{ "status": "healthy" }
```

---

### 🎉 Create Party

```
POST /api/v1/party
```

Request:
```json
{
  "player_uuid": "abc-123",
  "player_name": "Christoph",
  "mode": "golf",
  "target_score": 500
}
```

Response:
```json
{
  "party_id": 1,
  "party_code": "ABC123"
}
```

| Validation | Error |
|---|---|
| `player_uuid` required | `400` |
| `player_name` required | `400` |
| `mode` must be `classic` or `golf` | `400` |
| `target_score` must be >= 1 | `400` |

---

### 🚪 Join Party

```
POST /api/v1/party/join/:code
```

Request:
```json
{
  "player_uuid": "def-456",
  "player_name": "Max"
}
```

Response:
```json
{
  "party_id": 1,
  "party_code": "ABC123",
  "mode": "golf",
  "target_score": 500,
  "players": [
    { "name": "Christoph", "total_score": 0 },
    { "name": "Max", "total_score": 0 }
  ]
}
```

| Error | Status |
|---|---|
| Party not found | `404` |
| Party already started | `400` |
| Player already in party | `400` |

---

### 📊 Get Party Status

```
GET /api/v1/party/:id
```

Response:
```json
{
  "party_id": 1,
  "party_code": "ABC123",
  "mode": "golf",
  "status": "playing",
  "target_score": 500,
  "players": [
    { "name": "Christoph", "total_score": 0 },
    { "name": "Max", "total_score": 25 }
  ]
}
```

> Party status values: `waiting` | `playing` | `finished`

---

### ▶️ Start Party

```
POST /api/v1/party/:id/start
```

Request:
```json
{ "player_uuid": "abc-123" }
```

Response:
```json
{ "success": true }
```

| Error | Status |
|---|---|
| Party not found | `404` |
| Party already started | `400` |
| Need at least 2 players | `400` |
| Only host can start | `403` |
| Player not in party | `403` |

---

### 🥇 Report Round Winner

```
POST /api/v1/party/:id/round/winner
```

Request:
```json
{ "player_uuid": "abc-123" }
```

Response:
```json
{ "round_id": 1 }
```

> ⚠️ The `round_id` must be passed to all subsequent score submissions for this round.

| Error | Status |
|---|---|
| Party not found | `404` |
| Game not started | `400` |
| Player not in party | `403` |

---

### 📷 Submit Score

```
POST /api/v1/party/:id/round/score
```

Request:
```json
{
  "player_uuid": "def-456",
  "round_id": 1,
  "points": 25,
  "image_base64": "..."
}
```

> `image_base64` is optional. If provided, the image is stored on disk.

Response:
```json
{
  "total_score": 25,
  "game_over": false
}
```

Score logic:
- ⚡ `classic` → points added to the **round winner**
- ⛳ `golf` → points added to the **submitting player**

> 🔔 Game over is only triggered when **all players** (except the winner) have submitted their scores.

| Error | Status |
|---|---|
| Party / round / player not found | `404` |
| Game not started | `400` |
| Points must be >= 0 | `400` |
| Already submitted for this round | `400` |
| Winner cannot submit score | `400` |
| Player not in party | `403` |

---

### 📡 Connect WebSocket

```
WS /api/v1/party/:id/ws?player_uuid=abc-123
```

- Connection stays open for the duration of the game
- Server pushes events to all connected clients in the party
- Reconnect if connection drops

---

## 📢 WebSocket Events

All events follow this structure:

```json
{
  "party_id": 1,
  "event": "event_name",
  "payload": { }
}
```

### 👋 `player_joined`
```json
{ "payload": { "player_name": "Max" } }
```

### ▶️ `game_started`
```json
{ "payload": {} }
```

### 🥇 `round_winner`
```json
{ "payload": { "player_name": "Christoph" } }
```

### 📊 `score_update`
```json
{
  "payload": {
    "player_name": "Max",
    "points": 25,
    "total_score": 25,
    "scores": [
      { "player_name": "Christoph", "total_score": 0 },
      { "player_name": "Max", "total_score": 25 }
    ]
  }
}
```

### 🏁 `game_over`
```json
{
  "payload": {
    "winner_name": "Christoph",
    "scores": [
      { "player_name": "Christoph", "total_score": 45 },
      { "player_name": "Max", "total_score": 505 }
    ]
  }
}
```

---

## ❌ Error Response Format

```json
{ "error": "description of the error" }
```

| Status | Meaning |
|---|---|
| ✅ `200` | Success |
| ⚠️ `400` | Invalid input / business logic error |
| 🚫 `403` | Forbidden |
| 🔍 `404` | Resource not found |
| 💥 `500` | Internal server error |

---

## 🗄️ Database Schema

```
Party
  id, code, mode, target_score, status, created_at, updated_at

Player
  id, uuid, name, created_at, updated_at

PartyPlayer
  id, party_id, player_id, total_score, created_at
  → First entry per party = Host

Round
  id, party_id, winner_id, created_at

RoundScore
  id, round_id, player_id, points, image_path, created_at
```