import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../party/create_party_screen.dart';
import '../party/join_party_screen.dart';
import '../../widgets/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _name = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString(StorageKeys.playerName) ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Hintergrund Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0F1117),
                        const Color(0xFF1A1D2E),
                        const Color(0xFF0F1117),
                      ]
                    : [
                        const Color(0xFFF5F5F5),
                        const Color(0xFFFFEEEE),
                        const Color(0xFFF5F5F5),
                      ],
              ),
            ),
          ),

          // Dekorativer Kreis oben rechts
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.07),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'UNO Vision',
                        style: AppTextStyles.titleLarge(context),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () async {
                          final updated = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            builder: (_) => const SettingsModal(),
                          );
                          if (updated == true) _loadName();
                        },
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),

                        // Begrüssung
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '👋 Hallo,',
                                style: AppTextStyles.displayMedium(context)
                                    .copyWith(
                                      color: AppColors.textSecondaryDark,
                                      fontSize: 20,
                                    ),
                              ).animate().fadeIn(duration: 400.ms),
                              Text(
                                _name.isEmpty ? 'Spieler!' : '$_name!',
                                style: AppTextStyles.displayLarge(context),
                              ).animate().fadeIn(
                                delay: 100.ms,
                                duration: 400.ms,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Bereit zu spielen?',
                                style: AppTextStyles.bodyLarge(
                                  context,
                                ).copyWith(color: AppColors.textSecondaryDark),
                              ).animate().fadeIn(
                                delay: 200.ms,
                                duration: 400.ms,
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 3),

                        // Buttons
                        PrimaryButton(
                              label: 'Party erstellen',
                              icon: Icons.celebration_outlined,
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CreatePartyScreen(),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 400.ms)
                            .slideY(begin: 0.3, end: 0),

                        const SizedBox(height: 12),

                        SecondaryButton(
                              label: 'Party joinen',
                              icon: Icons.login_outlined,
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const JoinPartyScreen(),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 400.ms)
                            .slideY(begin: 0.3, end: 0),

                        const Spacer(),
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
