class Player {
  final String name;
  final int totalScore;

  const Player({required this.name, required this.totalScore});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(name: json['name'], totalScore: json['total_score'] ?? 0);
  }
}
