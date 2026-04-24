import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../party/lobby_screen.dart';
import '../../services/services.dart';

class JoinPartyScreen extends ConsumerStatefulWidget {
  const JoinPartyScreen({super.key});

  @override
  ConsumerState<JoinPartyScreen> createState() => _JoinPartyScreenState();
}

class _JoinPartyScreenState extends ConsumerState<JoinPartyScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _joinParty(String code) async {
    if (code.length != 6) return;
    setState(() => _isLoading = true);
    try {
      final party = await ref.read(partyServiceProvider).joinParty(code: code);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LobbyScreen(party: party, isHost: false),
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
        setState(() {
          _isLoading = false;
          _code = '';
          _controller.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
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
                        'Party joinen',
                        style: AppTextStyles.titleLarge(context),
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

                        Text(
                          'Party Code eingeben',
                          style: AppTextStyles.titleLarge(context),
                        ).animate().fadeIn(duration: 400.ms),

                        const SizedBox(height: 8),

                        Text(
                          'Wird automatisch gejoint nach 6 Zeichen',
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: AppColors.textSecondaryDark),
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 40),

                        // OTP Boxes
                        GestureDetector(
                          onTap: () => _focusNode.requestFocus(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (index) {
                              final hasChar = index < _code.length;
                              final isActive = index == _code.length;

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: 44,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.white,
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.primary
                                        : hasChar
                                        ? AppColors.primary.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.grey.withValues(alpha: 0.3),
                                    width: isActive ? 2 : 1.5,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    hasChar ? _code[index] : '',
                                    style: AppTextStyles.titleLarge(context)
                                        .copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ).animate().fadeIn(
                                delay: Duration(milliseconds: index * 50),
                              );
                            }),
                          ),
                        ),

                        // Verstecktes TextField
                        Opacity(
                          opacity: 0,
                          child: SizedBox(
                            height: 1,
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              maxLength: 6,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.characters,
                              onChanged: (value) {
                                final upper = value.toUpperCase();
                                // Controller auf Uppercase setzen
                                _controller.value = _controller.value.copyWith(
                                  text: upper,
                                  selection: TextSelection.collapsed(
                                    offset: upper.length,
                                  ),
                                );
                                setState(() => _code = upper);
                                if (upper.length == 6) {
                                  _joinParty(upper);
                                }
                              },
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Loading
                        if (_isLoading)
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ).animate().fadeIn(),

                        const Spacer(flex: 3),
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
