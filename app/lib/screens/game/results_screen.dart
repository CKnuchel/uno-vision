import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../home/home_screen.dart';
import '../party/lobby_screen.dart';
import 'history_screen.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../../services/services.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final Party party;
  final List<Player> players;
  final String winnerName;

  const ResultsScreen({
    super.key,
    required this.party,
    required this.players,
    required this.winnerName,
  });

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  late ConfettiController _confettiController;
  bool _isRestarting = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _restartParty() async {
    setState(() => _isRestarting = true);
    try {
      final newParty = await ref
          .read(partyServiceProvider)
          .restartParty(widget.party.id);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LobbyScreen(party: newParty, isHost: true),
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
      if (mounted) setState(() => _isRestarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGolfMode = widget.party.mode == 'golf';

    return Scaffold(
      body: Stack(
        children: [
          // Hintergrund
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF1A0A0A),
                        const Color(0xFF0F1117),
                        const Color(0xFF1A1D2E),
                      ]
                    : [const Color(0xFFFFEEEE), const Color(0xFFF5F5F5)],
              ),
            ),
          ),

          // Dekorative Kreise
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Konfetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                AppColors.primary,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Trophy
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 48)),
                    ),
                  ).animate().scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Gewinner',
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textSecondaryDark),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 8),

                  Text(
                    widget.winnerName,
                    style: AppTextStyles.displayLarge(
                      context,
                    ).copyWith(color: AppColors.primary),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 32),

                  // Rangliste
                  Text(
                    'Rangliste',
                    style: AppTextStyles.titleMedium(context),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 8),
                  ScoreCard(
                    players: widget.players,
                    isGolfMode: isGolfMode,
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

                  const Spacer(),

                  // Buttons
                  PrimaryButton(
                    label: 'Nochmal 🔄',
                    onPressed: _restartParty,
                    isLoading: _isRestarting,
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 8),

                  SecondaryButton(
                    label: 'Spielverlauf 📜',
                    icon: Icons.history,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HistoryScreen(partyId: widget.party.id),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 8),

                  SecondaryButton(
                    label: 'Home 🏠',
                    icon: Icons.home_outlined,
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    ),
                  ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
