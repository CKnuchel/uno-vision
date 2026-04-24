import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/network/api_client.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final int partyId;

  const HistoryScreen({super.key, required this.partyId});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<dynamic> _rounds = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final client = ApiClient();
      final data = await client.get('/party/${widget.partyId}/rounds');
      setState(() {
        _rounds = data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Hintergrund
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF0F1117), const Color(0xFF1A1D2E)]
                    : [const Color(0xFFF5F5F5), const Color(0xFFFFEEEE)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Spielverlauf',
                        style: AppTextStyles.titleLarge(context),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? _buildSkeleton(isDark)
                      : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: AppTextStyles.bodyLarge(context),
                          ),
                        )
                      : _rounds.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('📋', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              Text(
                                'Keine Runden vorhanden',
                                style: AppTextStyles.bodyLarge(
                                  context,
                                ).copyWith(color: AppColors.textSecondaryDark),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: _rounds.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _RoundCard(
                                  round: _rounds[index],
                                  index: index,
                                  isDark: isDark,
                                )
                                .animate()
                                .fadeIn(
                                  delay: Duration(milliseconds: index * 100),
                                )
                                .slideY(begin: 0.2, end: 0);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  final dynamic round;
  final int index;
  final bool isDark;

  const _RoundCard({
    required this.round,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final scores = round['scores'] as List? ?? [];
    final winnerName = round['winner_name'] ?? '';
    final roundId = round['round_id'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Text(
                  'Runde $roundId',
                  style: AppTextStyles.labelMedium(
                    context,
                  ).copyWith(color: AppColors.primary),
                ),
              ),
              const Spacer(),
              Text(
                '👑 $winnerName',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.grey.withValues(alpha: 0.15)),
          const SizedBox(height: 8),

          // Scores
          ...scores.map((score) {
            final imageUrl = score['image_url'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  // Foto
                  if (imageUrl != null)
                    GestureDetector(
                      onTap: () => _showFullImage(context, imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(width: 48),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 20,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      score['player_name'] ?? '',
                      style: AppTextStyles.bodyLarge(context),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      '${score['points']} Pkt.',
                      style: AppTextStyles.labelMedium(
                        context,
                      ).copyWith(color: AppColors.textSecondaryDark),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
