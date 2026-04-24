import '../models/player.dart';

class Party {
  final int id;
  final String code;
  final String mode;
  final int targetScore;
  final String status;
  final List<Player> players;

  const Party({
    required this.id,
    required this.code,
    required this.mode,
    required this.targetScore,
    required this.status,
    required this.players,
  });

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      id: json['party_id'],
      code: json['party_code'],
      mode: json['mode'],
      targetScore: json['target_score'],
      status: json['status'] ?? 'waiting',
      players: (json['players'] as List? ?? [])
          .map((p) => Player.fromJson(p))
          .toList(),
    );
  }
}
