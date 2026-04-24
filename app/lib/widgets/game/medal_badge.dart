import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

class MedalBadge extends StatelessWidget {
  final int rank;

  const MedalBadge({super.key, required this.rank});

  String get _medal {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      return Text(_medal, style: const TextStyle(fontSize: 24));
    }
    return SizedBox(
      width: 32,
      child: Text(
        '$rank.',
        style: AppTextStyles.bodyMedium(context),
        textAlign: TextAlign.center,
      ),
    );
  }
}
