import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/primary_button.dart';
import '../game/game_screen.dart';
import '../home/home_screen.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../../services/services.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final Party party;
  final bool isHost;

  const LobbyScreen({
    super.key,
    required this.party,
    required this.isHost,
  });

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen>
    with WidgetsBindingObserver {
  late Party _party;
  bool _isStarting = false;
  bool _isLeaving = false;
  String _playerUUID = '';
  StreamSubscription<WsEvent>? _wsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _party = widget.party;
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - refresh data and reconnect
      _refreshParty();
      final ws = ref.read(websocketServiceProvider);
      ws.connect(_party.id, _playerUUID);
    }
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _playerUUID = prefs.getString(StorageKeys.playerUUID) ?? '';

    final ws = ref.read(websocketServiceProvider);
    ws.connect(_party.id, _playerUUID);

    _wsSubscription = ws.events.listen((event) {
      if (!mounted) return;
      switch (event.event) {
        case WsEvents.playerJoined:
          _refreshParty();
        case WsEvents.playerLeft:
          _refreshParty();
        case WsEvents.partyCancelled:
          _handlePartyCancelled(event.payload);
        case WsEvents.gameStarted:
          _navigateToGame();
      }
    });
  }

  void _handlePartyCancelled(Map<String, dynamic> payload) {
    final reason = payload['reason'] as String? ?? 'Party wurde abgebrochen';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reason),
        backgroundColor: AppColors.error,
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<bool> _onWillPop() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Party verlassen?'),
        content: const Text('Möchtest du die Party wirklich verlassen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  Future<void> _leaveParty() async {
    final shouldLeave = await _onWillPop();
    if (!shouldLeave) return;

    setState(() => _isLeaving = true);
    try {
      await ref.read(partyServiceProvider).leaveParty(_party.id);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
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
      if (mounted) setState(() => _isLeaving = false);
    }
  }

  Future<void> _refreshParty() async {
    try {
      final updated =
          await ref.read(partyServiceProvider).getPartyStatus(_party.id);
      if (mounted) setState(() => _party = updated);
    } catch (_) {}
  }

  void _navigateToGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameScreen(party: _party)),
    );
  }

  Future<void> _startParty() async {
    setState(() => _isStarting = true);
    try {
      await ref.read(partyServiceProvider).startParty(_party.id);
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
      if (mounted) setState(() => _isStarting = false);
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _party.code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kopiert! 📋'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wsSubscription?.cancel();
    ref.read(websocketServiceProvider).disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canStart = _party.players.length >= 2;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _leaveParty();
      },
      child: Scaffold(
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
                  children: [
                    const SizedBox(height: 16),

                    // App Bar
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _isLeaving ? null : _leaveParty,
                        ),
                        Text('UNO Vision',
                            style: AppTextStyles.titleLarge(context)),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Party Code Card – Glassmorphism
                  GestureDetector(
                    onTap: _copyCode,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Party Code',
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _party.code.split('').join(' '),
                            style:
                                AppTextStyles.displayLarge(context).copyWith(
                              letterSpacing: 8,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.copy,
                                  size: 14,
                                  color: AppColors.textSecondaryDark),
                              const SizedBox(width: 4),
                              Text(
                                'Tippen zum Kopieren',
                                style: AppTextStyles.bodyMedium(context)
                                    .copyWith(
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),

                  const SizedBox(height: 24),

                  // Spieler Header
                  Row(
                    children: [
                      Text('Spieler',
                          style: AppTextStyles.titleMedium(context)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                        child: Text(
                          '${_party.players.length}',
                          style: AppTextStyles.labelMedium(context).copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Spielerliste
                  Expanded(
                    child: ListView.separated(
                      itemCount: _party.players.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final player = _party.players[index];
                        final isHost = index == 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white,
                            border: Border.all(
                              color: isHost
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isHost)
                                const Text('👑 ',
                                    style: TextStyle(fontSize: 18))
                              else
                                const SizedBox(width: 26),
                              Text(
                                player.name,
                                style: AppTextStyles.bodyLarge(context)
                                    .copyWith(
                                  fontWeight: isHost
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(
                                delay: Duration(milliseconds: index * 100))
                            .slideX(begin: -0.2, end: 0);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Host: Start / Gast: Warten
                  if (widget.isHost) ...[
                    if (!canStart)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Mindestens 2 Spieler benötigt',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ),
                    PrimaryButton(
                      label: 'Spiel starten',
                      icon: Icons.play_arrow_rounded,
                      onPressed: canStart ? _startParty : null,
                      isLoading: _isStarting,
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Warten auf Host... ⏳',
                          style: AppTextStyles.bodyLarge(context).copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .fadeIn(duration: 800.ms)
                            .then()
                            .fadeOut(duration: 800.ms),
                      ],
                    ),
                  ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}