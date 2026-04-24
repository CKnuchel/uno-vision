class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  factory AppException.fromStatusCode(int statusCode, String message) {
    final german = _errorMap[message] ?? 'Ein Fehler ist aufgetreten';
    return AppException(german, statusCode: statusCode);
  }

  static const _errorMap = {
    'party not found': 'Party nicht gefunden',
    'party already started': 'Party bereits gestartet',
    'need at least 2 players': 'Mindestens 2 Spieler benötigt',
    'already submitted': 'Du hast bereits eingereicht',
    'only host can start the party': 'Nur der Host kann starten',
    'player is not in party': 'Du bist nicht in dieser Party',
    'player is already in party': 'Du bist bereits in dieser Party',
    'party is not joinable': 'Party kann nicht beigetreten werden',
    'winner cannot submit score': 'Gewinner kann keinen Score einreichen',
    'player already submitted score': 'Du hast bereits eingereicht',
    'game is not started': 'Spiel wurde noch nicht gestartet',
    'party not finished': 'Party ist noch nicht beendet',
  };

  @override
  String toString() => message;
}
