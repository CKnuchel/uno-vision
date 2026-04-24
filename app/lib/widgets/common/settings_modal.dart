import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/storage_provider.dart';
import '../../services/storage_service.dart';
import '../common/app_text_field.dart';
import '../common/primary_button.dart';

class SettingsModal extends ConsumerStatefulWidget {
  const SettingsModal({super.key});

  @override
  ConsumerState<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends ConsumerState<SettingsModal> {
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await ref.read(storageServiceProvider).getPlayerName();
    setState(() => _nameController.text = name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    await ref
        .read(storageServiceProvider)
        .savePlayerName(_nameController.text.trim());

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Padding(
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
          // Handle
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

          // Titel
          Text('⚙️ Einstellungen', style: AppTextStyles.titleLarge(context)),
          const SizedBox(height: 24),

          // Name
          Text('Name', style: AppTextStyles.titleMedium(context)),
          const SizedBox(height: 8),
          AppTextField(
            label: 'Dein Name',
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Speichern',
            icon: Icons.check_rounded,
            onPressed: _nameController.text.trim().isEmpty ? null : _saveName,
            isLoading: _isLoading,
          ),

          const Divider(height: 32),

          // Dark Mode Toggle
          Text('Erscheinungsbild', style: AppTextStyles.titleMedium(context)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('🌙'),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dark Mode',
                  style: AppTextStyles.bodyLarge(context),
                ),
              ),
              Switch(
                value: isDark,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                onChanged: (val) {
                  ref
                      .read(themeModeProvider.notifier)
                      .setMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
