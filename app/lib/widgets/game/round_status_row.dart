import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class RoundStatusRow extends StatelessWidget {
  final String playerName;
  final bool isWinner;
  final bool hasSubmitted;

  const RoundStatusRow({
    super.key,
    required this.playerName,
    required this.isWinner,
    required this.hasSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          // Status Icon
          SizedBox(
            width: 28,
            child: isWinner
                ? const Text('👑', style: TextStyle(fontSize: 18))
                : Icon(
                    hasSubmitted ? Icons.check_circle : Icons.cancel,
                    color: hasSubmitted ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(playerName, style: AppTextStyles.bodyLarge(context)),
          ),
          if (isWinner)
            Text(
              'Gewonnen!',
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            )
          else if (hasSubmitted)
            Text(
              'Eingereicht ✅',
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.success),
            )
          else
            Text(
              'Ausstehend ❌',
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.textSecondaryDark),
            ),
        ],
      ),
    );
  }
}
