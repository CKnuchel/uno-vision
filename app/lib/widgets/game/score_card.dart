import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/player.dart';
import 'medal_badge.dart';

class ScoreCard extends StatelessWidget {
  final List<Player> players;
  final bool isGolfMode;

  const ScoreCard({super.key, required this.players, required this.isGolfMode});

  List<Player> get _sortedPlayers {
    final sorted = List<Player>.from(players);
    sorted.sort(
      (a, b) => isGolfMode
          ? a.totalScore.compareTo(b.totalScore)
          : b.totalScore.compareTo(a.totalScore),
    );
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedPlayers;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: List.generate(sorted.length, (index) {
          final player = sorted[index];
          final isFirst = index == 0;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isFirst
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                MedalBadge(rank: index + 1),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    player.name,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: isFirst ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  '${player.totalScore} Pkt.',
                  style: AppTextStyles.titleMedium(
                    context,
                  ).copyWith(color: isFirst ? AppColors.primary : null),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
