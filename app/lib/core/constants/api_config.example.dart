// Copy this file to api_config.dart and enter your server URL
// NEVER commit api_config.dart to the repository!
//
// cp api_config.example.dart api_config.dart

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

// =============================================================================
// PRODUCTION CONFIG - Hier deine Domain eintragen!
// =============================================================================
const String productionApiUrl =
    'https://api-uno-vision.your-domain.com/api/v1';
const String productionWsUrl = 'wss://api-uno-vision.your-domain.com/api/v1';

// =============================================================================
// Debug URLs (für lokale Entwicklung)
// =============================================================================
const String _debugApiUrlAndroid = 'http://10.0.2.2:8080/api/v1';
const String _debugWsUrlAndroid = 'ws://10.0.2.2:8080/api/v1';
const String _debugApiUrlWeb = 'http://localhost:8080/api/v1';
const String _debugWsUrlWeb = 'ws://localhost:8080/api/v1';

// =============================================================================
// Getters (automatische Auswahl basierend auf Platform/Mode)
// =============================================================================
String get apiBaseUrl {
  if (kDebugMode) {
    return kIsWeb ? _debugApiUrlWeb : _debugApiUrlAndroid;
  }
  return productionApiUrl;
}

String get wsBaseUrl {
  if (kDebugMode) {
    return kIsWeb ? _debugWsUrlWeb : _debugWsUrlAndroid;
  }
  return productionWsUrl;
}
