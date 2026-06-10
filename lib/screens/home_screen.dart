import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_palette.dart';
import '../state/providers.dart';
import 'play_route.dart';
import 'settings_screen.dart';

/// Landing screen: branding, continue/play, and entry to settings.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
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
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    iconSize: 28,
                    icon: const Icon(Icons.settings_rounded,
                        color: AppPalette.textMuted),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                  ),
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
                if (!isFresh) ...[
                  const SizedBox(height: 12),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.surface,
        title: const Text('Restart progress?'),
        content: const Text(
            'This will set you back to Stage 1. Your best-reached stage is kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restart'),
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

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.bombBody,
            boxShadow: [
              BoxShadow(
                color: AppPalette.accent.withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.local_fire_department_rounded,
              size: 64, color: AppPalette.accent),
        ),
        const SizedBox(height: 20),
        const Text(
          'BOMBS &\nPUZZLES',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: AppPalette.textPrimary,
          ),
        ),
      ],
    );
  }
}
