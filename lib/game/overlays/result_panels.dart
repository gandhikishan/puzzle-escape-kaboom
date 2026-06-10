import 'package:flutter/material.dart';

import '../../core/app_palette.dart';

/// Shared frosted panel used for both win and lose results.
class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppPalette.accentSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Shown when the player clears every bomb on a stage.
class StageCompletePanel extends StatelessWidget {
  const StageCompletePanel({
    super.key,
    required this.stageNumber,
    required this.onNext,
    required this.onHome,
  });

  final int stageNumber;
  final VoidCallback onNext;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return _ResultPanel(
      title: 'Stage $stageNumber\nCleared!',
      icon: Icons.celebration_rounded,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onNext,
            child: const Text('NEXT STAGE'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onHome,
          child: const Text('Home', style: TextStyle(color: AppPalette.textMuted)),
        ),
      ],
    );
  }
}

/// Shown when the player runs out of lives on a stage.
class GameOverPanel extends StatelessWidget {
  const GameOverPanel({
    super.key,
    required this.stageNumber,
    required this.onRetry,
    required this.onHome,
    this.onWatchAd,
  });

  final int stageNumber;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  /// Optional rewarded-ad refill action; hidden when null.
  final VoidCallback? onWatchAd;

  @override
  Widget build(BuildContext context) {
    return _ResultPanel(
      title: 'Out of Lives',
      icon: Icons.heart_broken_rounded,
      children: [
        if (onWatchAd != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onWatchAd,
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: const Text('REFILL (AD)'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.surface,
              side: const BorderSide(color: AppPalette.accent, width: 2),
            ),
            child: const Text('RETRY'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onHome,
          child: const Text('Home', style: TextStyle(color: AppPalette.textMuted)),
        ),
      ],
    );
  }
}
