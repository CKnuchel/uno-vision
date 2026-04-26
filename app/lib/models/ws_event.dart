class WsEvent {
  final int partyId;
  final String event;
  final Map<String, dynamic> payload;

  const WsEvent({
    required this.partyId,
    required this.event,
    required this.payload,
  });

  factory WsEvent.fromJson(Map<String, dynamic> json) {
    return WsEvent(
      partyId: json['party_id'],
      event: json['event'],
      payload: json['payload'] as Map<String, dynamic>? ?? {},
    );
  }
}

// Event Namen als Konstanten
class WsEvents {
  WsEvents._();

  static const playerJoined = 'player_joined';
  static const playerLeft = 'player_left';
  static const partyCancelled = 'party_cancelled';
  static const gameStarted = 'game_started';
  static const roundWinner = 'round_winner';
  static const scoreUpdate = 'score_update';
  static const gameOver = 'game_over';
  static const partyRestarted = 'party_restarted';
}
