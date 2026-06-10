import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_palette.dart';
import '../state/providers.dart';

/// Settings: sound toggle, progress reset, and legal/about info.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final progress = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppPalette.textPrimary,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppPalette.background, AppPalette.backgroundDeep],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Card(
              child: SwitchListTile(
                value: settings.soundOn,
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).toggleSound(),
                title: const Text('Sound effects'),
                secondary: const Icon(Icons.volume_up_rounded),
                activeThumbColor: AppPalette.accent,
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: ListTile(
                leading: const Icon(Icons.flag_rounded),
                title: const Text('Best stage reached'),
                trailing: Text(
                  '${progress.highestStage}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppPalette.accentSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: ListTile(
                leading: const Icon(Icons.restart_alt_rounded),
                title: const Text('Reset progress'),
                onTap: () => _confirmReset(context, ref),
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip_rounded),
                title: const Text('Privacy policy'),
                subtitle: const Text(
                  'Opens the hosted policy in your browser',
                  style: TextStyle(color: AppPalette.textMuted),
                ),
                onTap: () => _showPrivacyInfo(context),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Bombs & Puzzles  -  v1.0.0',
                style: TextStyle(color: AppPalette.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.surface,
        title: const Text('Reset all progress?'),
        content: const Text('You will start again from Stage 1.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(progressProvider.notifier).reset();
    }
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.surface,
        title: const Text('Privacy policy'),
        content: const Text(
          'The privacy policy will be hosted online before release and linked '
          'here. The game stores progress only on your device and shows ads via '
          'Google AdMob.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
