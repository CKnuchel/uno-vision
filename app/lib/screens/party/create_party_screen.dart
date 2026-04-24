import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../party/lobby_screen.dart';
import '../../widgets/widgets.dart';
import '../../services/services.dart';

enum PartyMode { golf, classic }

class CreatePartyScreen extends ConsumerStatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  ConsumerState<CreatePartyScreen> createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends ConsumerState<CreatePartyScreen> {
  PartyMode _selectedMode = PartyMode.golf;
  final _targetScoreController = TextEditingController(text: '500');
  bool _isLoading = false;

  @override
  void dispose() {
    _targetScoreController.dispose();
    super.dispose();
  }

  void _showModeInfo(PartyMode mode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          mode == PartyMode.golf ? '⛳ Golf Modus' : '🏆 Classic Modus',
        ),
        content: Text(
          mode == PartyMode.golf
              ? 'Jeder Verlierer sammelt seine eigenen Punkte. Wer zuerst die Zielpunktzahl erreicht verliert. Der Spieler mit den wenigsten Punkten gewinnt!'
              : 'Der Rundengewinner sammelt die Punkte aller Verlierer. Wer zuerst die Zielpunktzahl erreicht gewinnt!',
          style: AppTextStyles.bodyLarge(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  Future<void> _createParty() async {
    final score = int.tryParse(_targetScoreController.text);
    if (score == null || score <= 0) return;

    setState(() => _isLoading = true);
    try {
      final party = await ref
          .read(partyServiceProvider)
          .createParty(
            mode: _selectedMode == PartyMode.golf ? 'golf' : 'classic',
            targetScore: score,
          );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LobbyScreen(party: party, isHost: true),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                        'Party erstellen',
                        style: AppTextStyles.titleLarge(context),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Spielmodus
                        Text(
                          'Spielmodus',
                          style: AppTextStyles.titleMedium(context),
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 12),

                        _ModeCard(
                              emoji: '⛳',
                              title: 'Golf',
                              subtitle: 'Wenigste Punkte gewinnt',
                              selected: _selectedMode == PartyMode.golf,
                              onTap: () => setState(
                                () => _selectedMode = PartyMode.golf,
                              ),
                              onInfo: () => _showModeInfo(PartyMode.golf),
                              isDark: isDark,
                            )
                            .animate()
                            .fadeIn(delay: 100.ms)
                            .slideX(begin: -0.2, end: 0),

                        const SizedBox(height: 8),

                        _ModeCard(
                              emoji: '🏆',
                              title: 'Classic',
                              subtitle: 'Meiste Punkte gewinnt',
                              selected: _selectedMode == PartyMode.classic,
                              onTap: () => setState(
                                () => _selectedMode = PartyMode.classic,
                              ),
                              onInfo: () => _showModeInfo(PartyMode.classic),
                              isDark: isDark,
                            )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideX(begin: -0.2, end: 0),

                        const SizedBox(height: 32),

                        // Zielpunktzahl
                        Text(
                          'Zielpunktzahl',
                          style: AppTextStyles.titleMedium(context),
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Zielpunktzahl',
                          controller: _targetScoreController,
                          keyboardType: TextInputType.number,
                        ).animate().fadeIn(delay: 400.ms),

                        const Spacer(),

                        PrimaryButton(
                              label: 'Party erstellen',
                              icon: Icons.celebration_outlined,
                              onPressed: _createParty,
                              isLoading: _isLoading,
                            )
                            .animate()
                            .fadeIn(delay: 500.ms)
                            .slideY(begin: 0.3, end: 0),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onInfo;
  final bool isDark;

  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.onInfo,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.grey.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium(
                      context,
                    ).copyWith(color: selected ? AppColors.primary : null),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textSecondaryDark),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 22,
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onInfo,
              child: Icon(
                Icons.info_outline,
                size: 20,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
