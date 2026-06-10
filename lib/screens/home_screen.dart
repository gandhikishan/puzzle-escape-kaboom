import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_palette.dart';
import '../core/app_share.dart';
import '../state/providers.dart';
import 'play_route.dart';
import 'settings_screen.dart';

/// Landing screen: branding, continue/play, and entry to settings.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    // Watching this grants the once-per-day free hint when the app is opened.
    final hints = ref.watch(hintsProvider);
    final isFresh = progress.currentStage == 1 && progress.highestStage == 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppPalette.background, AppPalette.backgroundDeep],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _HintChip(count: hints),
                    Row(
                      children: [
                        IconButton(
                          iconSize: 26,
                          icon: const Icon(Icons.ios_share_rounded,
                              color: AppPalette.textMuted),
                          tooltip: 'Share app',
                          onPressed: AppShare.shareApp,
                        ),
                        IconButton(
                          iconSize: 28,
                          icon: const Icon(Icons.settings_rounded,
                              color: AppPalette.textMuted),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                const _Logo(),
                const SizedBox(height: 12),
                Text(
                  isFresh
                      ? 'Tap. Launch. Boom.'
                      : 'Best stage reached: ${progress.highestStage}',
                  style: const TextStyle(
                    color: AppPalette.textMuted,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _startPlay(context),
                    child: Text(isFresh
                        ? 'PLAY'
                        : 'CONTINUE  -  STAGE ${progress.currentStage}'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: AppShare.shareApp,
                    icon: const Icon(Icons.ios_share_rounded, size: 20),
                    label: const Text('INVITE FRIENDS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.textPrimary,
                      side: const BorderSide(color: AppPalette.accent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (!isFresh) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _confirmRestart(context, ref),
                    child: const Text(
                      'Restart from Stage 1',
                      style: TextStyle(color: AppPalette.textMuted),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startPlay(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlayRoute()),
    );
  }

  Future<void> _confirmRestart(BuildContext context, WidgetRef ref) async {
    final currentStage = ref.read(progressProvider).currentStage;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.surface,
        title: const Text(
          'Restart from Stage 1?',
          style: TextStyle(color: AppPalette.textPrimary),
        ),
        content: Text(
          'You are on Stage $currentStage. Restarting sends you all the way '
          'back to Stage 1. This cannot be undone (your best-reached stage '
          'badge is kept).',
          style: const TextStyle(color: AppPalette.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep my progress'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restart from Stage 1'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Keep the highest-reached badge but send the player back to stage 1.
      ref.read(progressProvider.notifier).reset();
    }
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_rounded,
              color: AppPalette.success, size: 20),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'hints',
            style: TextStyle(color: AppPalette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppPalette.accent.withValues(alpha: 0.5),
                blurRadius: 48,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Image.asset('assets/branding/logo.png'),
        ),
        const SizedBox(height: 20),
        const Text(
          'PUZZLE\nESCAPE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 42,
            height: 1.02,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: AppPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'KABOOM',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
            color: AppPalette.accent,
          ),
        ),
      ],
    );
  }
}
