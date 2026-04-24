import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../game/results_screen.dart';
import '../game/scan_screen.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../../services/services.dart';

class GameScreen extends ConsumerStatefulWidget {
  final Party party;

  const GameScreen({super.key, required this.party});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late Party _party;
  late List<Player> _players;
  String? _roundWinnerName;
  int? _currentRoundId;
  bool _hasReportedWin = false;
  bool _hasSubmittedScore = false;
  bool _isReportingWin = false;
  final Set<String> _submittedPlayers = {};

  @override
  void initState() {
    super.initState();
    _party = widget.party;
    _players = widget.party.players;
    _init();
  }

  Future<void> _init() async {
    await SharedPreferences.getInstance();

    final ws = ref.read(websocketServiceProvider);
    ws.events.listen((event) {
      if (!mounted) return;
      _handleWsEvent(event);
    });
  }

  void _handleWsEvent(WsEvent event) {
    switch (event.event) {
      case WsEvents.roundWinner:
        setState(() {
          _roundWinnerName = event.payload['player_name'];
          _currentRoundId = event.payload['round_id'];
          _hasReportedWin = false;
          _hasSubmittedScore = false;
          _submittedPlayers.clear();
          _submittedPlayers.add(event.payload['player_name']);
        });

      case WsEvents.scoreUpdate:
        final scores = event.payload['scores'] as List?;
        if (scores != null) {
          setState(() {
            _players = scores
                .map((s) => Player(
                      name: s['player_name'],
                      totalScore: s['total_score'],
                    ))
                .toList();
            _submittedPlayers.add(event.payload['player_name']);
          });
        }

      case WsEvents.gameOver:
        final scores = event.payload['scores'] as List?;
        final winnerName = event.payload['winner_name'];
        if (scores != null) {
          final players = scores
              .map((s) => Player(
                    name: s['player_name'],
                    totalScore: s['total_score'],
                  ))
              .toList();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ResultsScreen(
                party: _party,
                players: players,
                winnerName: winnerName,
              ),
            ),
          );
        }
    }
  }

  Future<void> _reportWin() async {
    setState(() => _isReportingWin = true);
    try {
      final roundId =
          await ref.read(partyServiceProvider).reportWinner(_party.id);
      setState(() {
        _currentRoundId = roundId;
        _hasReportedWin = true;
        _hasSubmittedScore = false;
      });
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
      if (mounted) setState(() => _isReportingWin = false);
    }
  }

  void _showManualScoreEntry() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Punkte eingeben',
                style: AppTextStyles.titleLarge(context)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Punkte'),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Bestätigen',
              icon: Icons.check_rounded,
              onPressed: () async {
                final points = int.tryParse(controller.text);
                if (points == null || _currentRoundId == null) return;
                Navigator.of(context).pop();
                await _submitScore(points);
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Abbrechen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitScore(int points) async {
    if (_currentRoundId == null) return;
    try {
      await ref.read(partyServiceProvider).submitScore(
            partyId: _party.id,
            roundId: _currentRoundId!,
            points: points,
          );
      setState(() => _hasSubmittedScore = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGolfMode = _party.mode == 'golf';

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color:
                              AppColors.primary.withValues(alpha: 0.15),
                        ),
                        child: Text(
                          isGolfMode ? '⛳ Golf' : '🏆 Classic',
                          style:
                              AppTextStyles.labelMedium(context).copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.grey.withValues(alpha: 0.15),
                        ),
                        child: Text(
                          '${_party.targetScore} Pkt.',
                          style:
                              AppTextStyles.labelMedium(context).copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  // Rangliste
                  Text('Rangliste',
                          style: AppTextStyles.titleMedium(context))
                      .animate()
                      .fadeIn(delay: 100.ms),
                  const SizedBox(height: 8),
                  ScoreCard(players: _players, isGolfMode: isGolfMode)
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 24),

                  // Aktuelle Runde
                  if (_roundWinnerName != null) ...[
                    Text('Aktuelle Runde',
                            style: AppTextStyles.titleMedium(context))
                        .animate()
                        .fadeIn(),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white,
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: _players.map((player) {
                          final isWinner =
                              player.name == _roundWinnerName;
                          final hasSubmitted =
                              _submittedPlayers.contains(player.name);
                          return RoundStatusRow(
                            playerName: player.name,
                            isWinner: isWinner,
                            hasSubmitted: hasSubmitted,
                          );
                        }).toList(),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 16),
                  ],

                  const Spacer(),

                  // Action Buttons
                  if (!_hasReportedWin && _roundWinnerName == null)
                    PrimaryButton(
                      label: 'Ich hab gewonnen! 👑',
                      onPressed: _reportWin,
                      isLoading: _isReportingWin,
                    ).animate().fadeIn().slideY(begin: 0.3, end: 0),

                  if (_roundWinnerName != null &&
                      !_hasReportedWin &&
                      !_hasSubmittedScore) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _currentRoundId == null
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ScanScreen(
                                          partyId: _party.id,
                                          roundId: _currentRoundId!,
                                          onConfirm: (points, imagePath) {
                                            Navigator.of(context).pop();
                                            _submitScore(points);
                                          },
                                        ),
                                      ),
                                    ),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Scan'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showManualScoreEntry,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Manuell'),
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                  ],

                  if (_hasSubmittedScore || _hasReportedWin)
                    Center(
                      child: Text(
                        'Warten auf andere Spieler... ⏳',
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .fadeIn(duration: 800.ms)
                          .then()
                          .fadeOut(duration: 800.ms),
                    ),

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