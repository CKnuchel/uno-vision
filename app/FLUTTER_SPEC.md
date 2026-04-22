# 📱 UNO Vision – Flutter App Specification

## 🎨 Design System

### Colors

```dart
// Light Mode
background:     #F5F5F5   // Helles Grau
surface:        #FFFFFF   // Weiss (Cards)
surfaceVariant: #EFEFEF   // Leicht grau (Input Fields)
primary:        #FF3B3B   // Leuchtendes Rot (Akzent)
onPrimary:      #FFFFFF   // Text auf Primary
text:           #1A1A1A   // Dunkler Text
textSecondary:  #6B6B6B   // Grauer Text
success:        #34C759   // Grün (Häkchen)
error:          #FF3B3B   // Rot (Fehler)
shadow:         #00000015 // Schatten

// Dark Mode
background:     #0F1117   // Dunkles Navy
surface:        #1A1D2E   // Card Hintergrund (Glassmorphism)
surfaceVariant: #252838   // Input Fields
primary:        #FF3B3B   // Gleiche Akzentfarbe
onPrimary:      #FFFFFF
text:           #F5F5F5   // Heller Text
textSecondary:  #9A9AB0   // Grauer Text
success:        #34C759
error:          #FF3B3B
```

### Typography

```dart
// Schrift: Inter (Google Fonts)
displayLarge:  Inter Bold    32px    // Grosser Titel (Gewinner etc.)
displayMedium: Inter Bold    24px    // Screen Titel
titleLarge:    Inter SemiBold 20px  // Card Titel
titleMedium:   Inter SemiBold 16px  // Section Titel
bodyLarge:     Inter Regular  16px  // Fliesstext
bodyMedium:    Inter Regular  14px  // Sekundärer Text
labelLarge:    Inter SemiBold 16px  // Button Text
labelMedium:   Inter Medium   14px  // Badge / Tag
```

### Components

```dart
// Buttons → Pill-Shape (border-radius: 50)
PrimaryButton:    Rot gefüllt, weisser Text, Icon links
SecondaryButton:  Transparent, roter Border, roter Text, Icon links
DangerButton:     Rot gefüllt (für kritische Aktionen)

// Cards
LightMode: Weiss, border-radius 16px, leichter Schatten
DarkMode:  Glassmorphism – backdrop-blur, 20% Opacity, subtiler Border

// Input Fields
border-radius: 12px
Border:        Grau, bei Focus → Rot
Label:         Oben schwebend (floating label)

// Snackbar (Fehler/Erfolg)
Position:      Unten
Error:         Roter Hintergrund, ❌ Icon, weisser Text
Success:       Grüner Hintergrund, ✅ Icon, weisser Text
Duration:      3 Sekunden
```

### Micro-Interactions

| Aktion | Feedback |
|---|---|
| Button Tap | Haptic Feedback (leichte Vibration) |
| Score eingereicht | ✅ Animation + grüner Flash |
| Game Over | 🎊 Konfetti Regen (confetti Package) |
| Karte erkannt | Kurzes "Ding" Sound |
| Code kopiert | "Kopiert!" Snackbar |
| Fehler | Roter Snackbar + Vibration |
| Loading | Skeleton Loading / Spinner |

---

## 📁 Projekt Struktur

```
app/
  lib/
    main.dart                   ← Einstiegspunkt, Theme Setup
    l10n/                       ← Lokalisierung (DE + EN)
      app_de.arb
      app_en.arb
    core/
      constants/
        api_constants.dart      ← API URLs
        storage_keys.dart       ← SharedPreferences Keys
      theme/
        app_theme.dart          ← Light + Dark Theme
        app_colors.dart         ← Farben
        app_text_styles.dart    ← Typografie
      network/
        api_client.dart         ← HTTP Client (Dio)
        websocket_client.dart   ← WebSocket Client
      storage/
        local_storage.dart      ← SharedPreferences Wrapper
      errors/
        app_exception.dart      ← Typisierte Fehler
    models/
      party.dart
      player.dart
      round_score.dart
      ws_event.dart             ← WebSocket Event Model
    services/
      party_service.dart        ← API Calls
      websocket_service.dart    ← WS Verbindung + Events
      storage_service.dart      ← Lokale Daten (UUID, Name)
      ml_service.dart           ← YOLO TFLite Erkennung
    widgets/
      common/
        primary_button.dart
        secondary_button.dart
        app_text_field.dart
        loading_overlay.dart
        error_snackbar.dart
        player_list_tile.dart
      game/
        score_card.dart
        round_status_row.dart
        medal_badge.dart
        uno_card_widget.dart  ← S/W Kärtchen Widget
    screens/
      welcome/
        welcome_screen.dart
      home/
        home_screen.dart
      party/
        create_party_screen.dart
        join_party_screen.dart
        lobby_screen.dart
      game/
        game_screen.dart
        scan_screen.dart
        results_screen.dart
    providers/                  ← State Management (Riverpod)
      party_provider.dart
      game_provider.dart
      websocket_provider.dart
      storage_provider.dart
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Network
  dio: ^5.0.0                   # HTTP Client
  web_socket_channel: ^2.4.0   # WebSocket

  # State Management
  flutter_riverpod: ^2.4.0     # State Management
  riverpod_annotation: ^2.3.0

  # Local Storage
  shared_preferences: ^2.2.0   # UUID + Name speichern

  # ML / Camera
  tflite_flutter: ^0.10.0      # YOLO TFLite
  camera: ^0.10.0              # Kamera Zugriff
  image: ^4.1.0                # Bildverarbeitung

  # UI
  google_fonts: ^6.1.0         # Inter Schrift
  confetti: ^0.7.0             # Konfetti Animation
  shimmer: ^3.0.0              # Skeleton Loading
  flutter_animate: ^4.3.0      # Animationen

  # Utils
  uuid: ^4.2.0                 # UUID generieren
  intl: ^0.18.0                # Lokalisierung

dev_dependencies:
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
  flutter_localizations:
    sdk: flutter
```

---

## 🗺️ Navigation

```
App Start
    │
    ├── Kein Name gespeichert → WelcomeScreen
    │
    └── Name vorhanden → HomeScreen
            │
            ├── Create Party → CreatePartyScreen
            │                       │
            │                       └── LobbyScreen (Host)
            │                               │
            │                               └── GameScreen
            │                                       │
            │                                       ├── ScanScreen (Modal)
            │                                       └── ResultsScreen
            │
            └── Join Party → JoinPartyScreen
                                    │
                                    └── LobbyScreen (Gast)
                                            │
                                            └── GameScreen
                                                    │
                                                    ├── ScanScreen (Modal)
                                                    └── ResultsScreen
```

---

## 📱 Screens

---

### 1. 👋 Welcome Screen

**Zweck:** Name und UUID beim ersten Start erfassen und lokal speichern.

**Wireframe:**
```
┌─────────────────────────┐
│                         │
│                         │
│   🎴  UNO Vision        │
│                         │
│   Willkommen!           │
│   Wie heisst du?        │
│                         │
│  ┌─────────────────┐    │
│  │ Dein Name       │    │  ← Auto-Capitalize ersten Buchstaben
│  └─────────────────┘    │
│                         │
│  ┌─────────────────┐    │
│  │  ✅ Los geht's  │    │  ← Disabled bis Name eingegeben
│  └─────────────────┘    │
│                         │
└─────────────────────────┘
```

**Logik:**
1. App startet → prüfe `SharedPreferences` auf gespeicherten Namen
2. Kein Name → zeige Welcome Screen
3. Nutzer gibt Namen ein → Button wird aktiv
4. Tap "Los geht's":
   - Generiere UUID (`uuid` Package) → speichere in SharedPreferences
   - Speichere Namen in SharedPreferences
   - Navigiere zu Home Screen

**Details:**
- `TextCapitalization.words` auf dem TextField
- Button disabled solange Feld leer
- Kein Back-Button (erster Start)

---

### 2. 🏠 Home Screen

**Zweck:** Haupteinstieg mit Party erstellen oder joinen.

**Wireframe:**
```
┌─────────────────────────┐
│  UNO Vision          ⚙️ │  ← Settings Icon (Name ändern)
│                         │
│                         │
│   👋 Hallo, Christoph!  │
│   Bereit zu spielen?    │
│                         │
│                         │
│  ┌─────────────────┐    │
│  │ 🎉 Party erstellen│  │  ← Primary Button (Rot)
│  └─────────────────┘    │
│                         │
│  ┌─────────────────┐    │
│  │ 🚪 Party joinen │    │  ← Secondary Button (Outline)
│  └─────────────────┘    │
│                         │
│                         │
└─────────────────────────┘
```

**Logik:**
1. Lade Name aus SharedPreferences
2. Zeige "Hallo, {Name}!"
3. Settings Icon → Modal zum Namen ändern
4. "Party erstellen" → CreatePartyScreen
5. "Party joinen" → JoinPartyScreen

---

### 2b. ⚙️ Settings Modal

**Zweck:** Name ändern, Sprache wählen, Dark/Light Mode umschalten.

**Wireframe:**
```
┌─────────────────────────┐
│  ⚙️ Einstellungen       │
│                         │
│  Name                   │
│  ┌─────────────────┐    │
│  │ Christoph       │    │  ← Änderbar, Auto-Capitalize
│  └─────────────────┘    │
│                         │
│  ┌─────────────────┐    │
│  │  ✅ Speichern   │    │  ← Disabled wenn kein Name
│  └─────────────────┘    │
│                         │
│  ─────────────────────  │
│                         │
│  Sprache                │
│  ┌─────────────────┐    │
│  │ 🇩🇪 Deutsch  ✓  │    │  ← Ausgewählt
│  ├─────────────────┤    │
│  │ 🇬🇧 English     │    │
│  └─────────────────┘    │
│                         │
│  ─────────────────────  │
│                         │
│  Erscheinungsbild       │
│  ┌──────────────────┐   │
│  │ 🌙 Dark Mode  🔘 │   │  ← Toggle
│  └──────────────────┘   │
│                         │
└─────────────────────────┘
```

**Logik:**
1. Öffnet als Modal (Bottom Sheet) vom Home Screen
2. Name vorausgefüllt mit gespeichertem Namen
3. "Speichern" Tap:
   - Neuen Namen in SharedPreferences speichern
   - Home Screen aktualisiert sich automatisch
   - Modal schliesst sich
4. Sprache wählen:
   - Auswahl in SharedPreferences speichern
   - App Sprache sofort wechseln (ohne Neustart)
5. Dark Mode Toggle:
   - Einstellung in SharedPreferences speichern
   - Theme sofort wechseln

**Local Storage Keys:**
```dart
const themeKey = 'theme_mode';      // 'dark' | 'light'
const languageKey = 'language';     // 'de' | 'en'
```

---

### 3. 🎮 Create Party Screen

**Zweck:** Spielmodus und Zielpunktzahl festlegen und Party erstellen.

**Wireframe:**
```
┌─────────────────────────┐
│  ←  Party erstellen     │
│                         │
│  Spielmodus             │
│  ┌─────────────────┐    │
│  │ ⛳ Golf      ℹ️ │ ✓  │  ← Ausgewählt (roter Border)
│  └─────────────────┘    │
│  ┌─────────────────┐    │
│  │ 🏆 Classic   ℹ️ │    │
│  └─────────────────┘    │
│                         │
│  Zielpunktzahl          │
│  ┌─────────────────┐    │
│  │ 500             │    │  ← Nur Zahlen, Default 500
│  └─────────────────┘    │
│                         │
│  ┌─────────────────┐    │
│  │ 🎉 Party erstellen│  │
│  └─────────────────┘    │
└─────────────────────────┘

// ℹ️ Modal – Golf:
┌─────────────────────────┐
│  ⛳ Golf Modus           │
│                         │
│  Jeder Verlierer sammelt│
│  seine eigenen Punkte.  │
│  Wer zuerst die         │
│  Zielpunktzahl erreicht │
│  verliert. Der Spieler  │
│  mit den wenigsten      │
│  Punkten gewinnt!       │
│                         │
│  ┌─────────────────┐    │
│  │     Verstanden  │    │
│  └─────────────────┘    │
└─────────────────────────┘
```

**Logik:**
1. Standard: Golf ausgewählt, Zielpunktzahl 500
2. ℹ️ Tap → Modal mit Erklärung
3. "Party erstellen" Tap:
   - Loading Spinner auf Button
   - `POST /api/v1/party` aufrufen
   - Erfolg → LobbyScreen (mit party_id, party_code)
   - Fehler → Roter Snackbar

---

### 4. 🚪 Join Party Screen

**Zweck:** Einer bestehenden Party via Code beitreten.

**Wireframe:**
```
┌─────────────────────────┐
│  ←  Party joinen        │
│                         │
│                         │
│   Party Code eingeben   │
│                         │
│  ┌─────────────────┐    │
│  │  _ _ _ _ _ _   │    │  ← 6 Zeichen, Auto-Uppercase
│  └─────────────────┘    │
│                         │
│   Nach 6 Zeichen wird   │
│   automatisch gejoint   │
│                         │
│   [Loading Spinner]     │  ← Erscheint nach 6 Zeichen
│                         │
└─────────────────────────┘
```

**Logik:**
1. TextField: `maxLength: 6`, `TextCapitalization.characters`
2. Bei 6 Zeichen → automatisch `POST /api/v1/party/join/:code`
3. Loading Spinner während API Call
4. Erfolg → LobbyScreen
5. Fehler:
   - Party nicht gefunden → "Party nicht gefunden ❌"
   - Party bereits gestartet → "Party bereits gestartet ❌"
   - Bereits in Party → "Du bist bereits in dieser Party ❌"

---

### 5. 🏟️ Lobby Screen

**Zweck:** Warten bis alle Spieler beigetreten sind, dann Spiel starten.

**Wireframe:**
```
┌─────────────────────────┐
│  UNO Vision             │
│                         │
│   Party Code            │
│  ┌─────────────────┐    │
│  │   A B C 1 2 3   │    │  ← Tap → Kopiert + "Kopiert!" Snackbar
│  │   📋 Kopieren   │    │
│  └─────────────────┘    │
│                         │
│  Spieler (2/8)          │
│  ┌─────────────────┐    │
│  │ 👑 Christoph    │    │  ← Host (Krone)
│  ├─────────────────┤    │
│  │    Max          │    │
│  ├─────────────────┤    │
│  │    Felix        │    │
│  └─────────────────┘    │
│                         │
│  [Nur für Host:]         │
│  ┌─────────────────┐    │
│  │ ▶️  Spiel starten│   │  ← Disabled wenn < 2 Spieler
│  └─────────────────┘    │
│                         │
│  [Für Gäste:]           │
│  Warten auf Host...⏳   │
│                         │
└─────────────────────────┘
```

**Logik:**
1. WebSocket verbinden → `WS /api/v1/party/:id/ws`
2. `player_joined` Event → Spielerliste aktualisieren (Animation!)
3. Code Tap → Clipboard + Snackbar "Kopiert! 📋"
4. Host sieht "Spiel starten" Button (disabled bei < 2 Spielern)
5. Gäste sehen "Warten auf Host..." mit Pulse Animation
6. "Spiel starten" Tap → `POST /api/v1/party/:id/start`
7. `game_started` WS Event → alle navigieren zu GameScreen

---

### 6. 🎯 Game Screen

**Zweck:** Hauptscreen während dem Spiel. Rangliste, Runden-Status und Aktionen.

**Wireframe:**
```
┌─────────────────────────┐
│  Golf Mode    500 Pkt.  │
│                         │
│  Rangliste              │
│  ┌─────────────────┐    │
│  │ 🥇 Christoph  0 │    │
│  ├─────────────────┤    │
│  │ 🥈 Felix     25 │    │
│  ├─────────────────┤    │
│  │ 🥉 Max       45 │    │
│  └─────────────────┘    │
│                         │
│  Aktuelle Runde         │
│  ┌─────────────────┐    │
│  │ 👑 Christoph    │    │  ← Rundengewinner
│  │ ✅ Felix        │    │  ← Score eingereicht
│  │ ❌ Max          │    │  ← Noch nicht eingereicht
│  └─────────────────┘    │
│                         │
│  ┌─────────────────┐    │
│  │ 👑 Ich hab gewonnen│ │
│  └─────────────────┘    │
│  ┌────────┐ ┌────────┐  │
│  │📷 Scan │ │✏️ Manuell│ │
│  └────────┘ └────────┘  │
└─────────────────────────┘

// Wenn eigener Score bereits eingereicht:
// → Scan + Manuell Buttons disabled/versteckt
// → "Warten auf andere Spieler..." anzeigen
```

**Logik:**
1. WebSocket bleibt offen
2. `score_update` Event → Rangliste + Rundenstatus aktualisieren
3. `round_winner` Event → Krone anzeigen
4. `game_over` Event → navigiere zu ResultsScreen
5. "Ich hab gewonnen" Tap:
   - `POST /api/v1/party/:id/round/winner`
   - Krone erscheint bei eigenem Namen
   - Button verschwindet
6. "Scan" Tap → ScanScreen (Modal/Bottom Sheet)
7. "Manuell" Tap → Score Entry Modal

**Score Entry Modal:**
```
┌─────────────────────────┐
│  Punkte eingeben        │
│                         │
│  ┌─────────────────┐    │
│  │  0              │    │  ← Nur Zahlen
│  └─────────────────┘    │
│                         │
│  ┌─────────────────┐    │
│  │  ✅ Bestätigen  │    │
│  └─────────────────┘    │
│  ┌─────────────────┐    │
│  │  Abbrechen      │    │
│  └─────────────────┘    │
└─────────────────────────┘
```

---

### 7. 📷 Scan Screen

**Zweck:** Karten mit Kamera scannen, YOLO erkennt Karten und berechnet Punkte.

**Wireframe:**
```
┌─────────────────────────┐
│  ←  Karten scannen      │
│                         │
│  ┌─────────────────┐    │
│  │                 │    │
│  │   [KAMERA       │    │
│  │    VORSCHAU]    │    │
│  │                 │    │
│  │  ┌───┐ ┌───┐   │    │  ← Bounding Boxes um erkannte Karten
│  │  │ 7 │ │+2 │   │    │
│  │  └───┘ └───┘   │    │
│  └─────────────────┘    │
│                         │
│  Erkannte Karten:       │
│  ┌──────────────────┐   │
│  │ ┌──┐             │   │
│  │ │7 │  7   → 7 Pkt│   │  ← S/W Kärtchen + Name + Punkte
│  │ └──┘             │   │
│  │ ┌──┐             │   │
│  │ │+2│  +2  →20 Pkt│   │
│  │ └──┘             │   │
│  │ ────────────────  │   │
│  │ Total:   27 Pkt.  │   │
│  └──────────────────┘   │
│                         │
│  ┌─────────────────┐    │
│  │  ✅ Bestätigen  │    │
│  └─────────────────┘    │
└─────────────────────────┘
```

**Logik:**
1. Kamera öffnen (`camera` Package)
2. Live-Frames an YOLO TFLite (`tflite_flutter`)
3. Erkannte Karten → Bounding Boxes auf Kamera-Preview
4. Label Mapping → Punkte berechnen
5. Liste der erkannten Karten mit S/W Kärtchen anzeigen
6. "Bestätigen" → `POST /api/v1/party/:id/round/score`
7. Bild als Base64 mitsenden (optional)
8. Erfolg → zurück zu GameScreen

**🃏 UnoCardWidget – S/W Kärtchen:**

Kleines schwarz-weisses Karten-Widget das neben jeder erkannten Karte angezeigt wird:

```dart
// widgets/game/uno_card_widget.dart
class UnoCardWidget extends StatelessWidget {
  final int label;  // YOLO Label 0-14

  const UnoCardWidget({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(1, 1),
          )
        ],
      ),
      child: Center(
        child: Text(
          _labelToSymbol(label),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
```

**Symbol Mapping pro Label:**

| Label | Karte | Symbol |
|---|---|---|
| 0 | 0 | `0` |
| 1 | 1 | `1` |
| 2 | 2 | `2` |
| 3 | 3 | `3` |
| 4 | 4 | `4` |
| 5 | 5 | `5` |
| 6 | 6 | `6` |
| 7 | 7 | `7` |
| 8 | 8 | `8` |
| 9 | 9 | `9` |
| 10 | +4 Wild | `+4` |
| 11 | +2 | `+2` |
| 12 | Reverse | `↺` |
| 13 | Skip | `⊘` |
| 14 | Wild | `W` |

```dart
String _labelToSymbol(int label) {
  const symbols = {
    0: '0', 1: '1', 2: '2', 3: '3', 4: '4',
    5: '5', 6: '6', 7: '7', 8: '8', 9: '9',
    10: '+4', 11: '+2', 12: '↺', 13: '⊘', 14: 'W',
  };
  return symbols[label] ?? '?';
}
```

**Label Mapping:**
```dart
const Map<int, int> labelToPoints = {
  0: 0,   // 0
  1: 1,   // 1
  2: 2,   // 2
  3: 3,   // 3
  4: 4,   // 4
  5: 5,   // 5
  6: 6,   // 6
  7: 7,   // 7
  8: 8,   // 8
  9: 9,   // 9
  10: 50, // +4 Wild
  11: 20, // +2
  12: 20, // Reverse
  13: 20, // Skip
  14: 50, // Wild
};
```

---

### 8. 🏆 Results Screen

**Zweck:** Spielergebnis anzeigen, Gewinner feiern.

**Wireframe:**
```
┌─────────────────────────┐
│                         │
│   🎊 🎊 🎊              │  ← Konfetti Animation
│                         │
│   🏆 Gewinner           │
│   Christoph             │  ← Gross, Bold
│   45 Punkte             │
│                         │
│  Rangliste              │
│  ┌─────────────────┐    │
│  │ 🥇 Christoph 45 │    │
│  ├─────────────────┤    │
│  │ 🥈 Felix     85 │    │
│  ├─────────────────┤    │
│  │ 🥉 Max      505 │    │  ← Roter Text (hat verloren)
│  └─────────────────┘    │
│                         │
│  ┌─────────────────┐    │
│  │ 🔄 Nochmal      │    │  ← Nur für Host sichtbar
│  └─────────────────┘    │
│  ┌─────────────────┐    │
│  │ 🏠 Home         │    │
│  └─────────────────┘    │
└─────────────────────────┘
```

**Logik:**
1. Konfetti Animation beim Öffnen
2. Gewinner gross anzeigen
3. Rangliste:
   - Golf: wenigste Punkte = Gewinner (grün), meiste = Verlierer (rot)
   - Classic: meiste Punkte = Gewinner (grün)
4. "Nochmal" (nur Host):
   - `POST /api/v1/party/:id/restart` (neuer Endpoint!)
   - Neue Party mit gleichen Spielern + gleichem Modus
   - Alle via WS Event zur neuen Lobby navigieren
5. "Home" → HomeScreen

---

## 🔌 API Integration

### HTTP Client (Dio)

```dart
// core/network/api_client.dart
class ApiClient {
  static const baseUrl = "http://YOUR_SERVER_IP:8080/api/v1";

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 10),
  ));

  // Interceptor für Error Handling
  // Alle Fehler → AppException
}
```

### WebSocket Client

```dart
// core/network/websocket_client.dart
class WebSocketClient {
  // Verbinden
  connect(partyId, playerUUID)

  // Events empfangen → Stream<WsEvent>
  Stream<WsEvent> get events

  // Verbindung trennen
  disconnect()

  // Auto-Reconnect bei Verbindungsabbruch
}
```

### WS Event Model

```dart
class WsEvent {
  final int partyId;
  final String event;      // player_joined, game_started, etc.
  final dynamic payload;

  // Factory Constructors pro Event Type
  factory WsEvent.fromJson(Map<String, dynamic> json)
}
```

---

## 💾 Local Storage

```dart
// SharedPreferences Keys
const playerUUIDKey = 'player_uuid';
const playerNameKey = 'player_name';
const themeKey      = 'theme_mode';   // 'dark' | 'light'
const languageKey   = 'language';     // 'de' | 'en'

// Beim ersten Start:
// 1. UUID generieren → speichern
// 2. Name eingeben → speichern

// Beim App Start:
// 1. UUID + Name laden
// 2. Kein Name → WelcomeScreen
// 3. Name vorhanden → HomeScreen
```

---

## 🌍 Lokalisierung

```
// Zuerst Deutsch, dann Englisch
// flutter_localizations + intl Package

l10n/
  app_de.arb    ← Deutsch (Standard)
  app_en.arb    ← Englisch

// Beispiel app_de.arb:
{
  "welcome": "Willkommen!",
  "enterName": "Wie heisst du?",
  "createParty": "Party erstellen",
  "joinParty": "Party joinen",
  "startGame": "Spiel starten",
  "iWon": "Ich hab gewonnen! 👑",
  "scanCards": "Karten scannen",
  "enterManually": "Manuell eingeben",
  "confirm": "Bestätigen",
  "cancel": "Abbrechen",
  "home": "Home",
  "playAgain": "Nochmal",
  "copied": "Kopiert! 📋",
  "waitingForHost": "Warten auf Host... ⏳",
  "waitingForPlayers": "Warten auf andere Spieler...",
  "settings": "Einstellungen",
  "save": "Speichern",
  "language": "Sprache",
  "appearance": "Erscheinungsbild",
  "darkMode": "Dark Mode",
  "name": "Name"
}
```

---

## ⚠️ Error Handling

```dart
// Alle API Fehler → AppException
class AppException {
  final String message;
  final int? statusCode;
}

// Mapping API Fehler → Deutsche Texte:
400 "party already started"    → "Party bereits gestartet"
400 "need at least 2 players"  → "Mindestens 2 Spieler benötigt"
400 "already submitted"        → "Du hast bereits eingereicht"
403 "only host can start"      → "Nur der Host kann starten"
404 "party not found"          → "Party nicht gefunden"
500                            → "Ein Fehler ist aufgetreten"
No Internet                    → "Keine Internetverbindung"

// Anzeige: Roter Snackbar unten
// ❌ [Fehlermeldung]
// Duration: 3 Sekunden
```

---

## 🔔 Berechtigungen (Android)

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

---

## ✅ Restart Endpoint (Backend) – Erledigt

```
POST /api/v1/party/:id/restart
Request:  { "player_uuid": "abc-123" }
Response: { "party_id": 2, "party_code": "XYZ789" }
```

WS Event bei Restart:
```json
{
  "party_id": 1,
  "event": "party_restarted",
  "payload": {
    "new_party_id": 2,
    "new_party_code": "XYZ789"
  }
}
```

App Logik beim `party_restarted` Event:
- Alle Spieler navigieren automatisch zur neuen Lobby
- Host landet direkt in der neuen Lobby