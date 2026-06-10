import 'package:flame/game.dart' hide Matrix4;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_palette.dart';
import '../core/game_sound.dart';
import '../game/bomb_game.dart';
import '../game/overlays/result_panels.dart';
import '../levels/level.dart';
import '../state/providers.dart';

/// Renders and runs a single stage. Stage progression, persistence and ads are
/// owned by the caller via the callbacks below, keeping this screen focused on
/// play + in-stage life tracking. There is exactly one game screen in the app.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    required this.stageNumber,
    required this.startingLives,
    required this.onNext,
    required this.onHome,
    this.onSound,
    this.onRequestRewardRefill,
    this.onStageCleared,
    this.onGameOver,
  });

  final Level level;
  final int stageNumber;
  final int startingLives;

  /// Called when the player taps "Next" after clearing the stage.
  final VoidCallback onNext;
  final VoidCallback onHome;
  final void Function(GameSound sound)? onSound;

  /// Shows a rewarded ad and resolves true if a reward was granted.
  final Future<bool> Function()? onRequestRewardRefill;

  /// Fired once when the stage is cleared (for analytics).
  final VoidCallback? onStageCleared;

  /// Fired once when the player runs out of lives (for analytics).
  final VoidCallback? onGameOver;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late BombGame _game;
  late int _lives;
  bool _won = false;
  bool _dead = false;

  final TransformationController _zoom = TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _lives = widget.startingLives;
    _game = BombGame(
      onWin: _handleWin,
      onLifeLost: _handleLifeLost,
      onSound: widget.onSound,
    )..loadLevel(widget.level);
    _zoom.addListener(_onZoomChanged);
  }

  @override
  void dispose() {
    _zoom.removeListener(_onZoomChanged);
    _zoom.dispose();
    super.dispose();
  }

  void _onZoomChanged() {
    final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.02;
    if (zoomed != _isZoomed) setState(() => _isZoomed = zoomed);
  }

  void _resetZoom() {
    _zoom.value = Matrix4.identity();
  }

  void _handleWin() {
    if (_won) return;
    setState(() => _won = true);
    widget.onStageCleared?.call();
  }

  void _handleLifeLost() {
    HapticFeedback.heavyImpact();
    setState(() {
      _lives = (_lives - 1).clamp(0, widget.startingLives);
      if (_lives <= 0) _dead = true;
    });
    if (_dead) widget.onGameOver?.call();
  }

  void _restartStage() {
    setState(() {
      _lives = widget.startingLives;
      _won = false;
      _dead = false;
    });
    _resetZoom();
    _game.loadLevel(widget.level);
  }

  Future<void> _watchAdToRefill() async {
    final granted = await widget.onRequestRewardRefill?.call() ?? false;
    if (granted && mounted) {
      _restartStage();
    }
  }

  void _useHint() {
    if (_won || _dead) return;
    final hints = ref.read(hintsProvider);
    if (hints <= 0) {
      _offerHintAd();
      return;
    }
    // Only spend a hint if a safe bomb was actually highlighted.
    if (_game.showHint()) {
      ref.read(hintsProvider.notifier).consume();
    }
  }

  Future<void> _offerHintAd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.surface,
        title: const Text('Out of hints',
            style: TextStyle(color: AppPalette.textPrimary)),
        content: const Text(
          'Watch a short video to earn '
          '${HintsNotifier.hintsPerAd} hints?',
          style: TextStyle(color: AppPalette.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Watch'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final granted = await ref.read(adsServiceProvider).showRewarded();
    if (!granted || !mounted) return;
    ref.read(hintsProvider.notifier).add(HintsNotifier.hintsPerAd);
    if (_game.showHint()) {
      ref.read(hintsProvider.notifier).consume();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: _zoom,
                  minScale: 1.0,
                  maxScale: 5.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: GameWidget(game: _game),
                ),
              ),
              Align(alignment: Alignment.topCenter, child: _buildHud()),
              if (!_won && !_dead && _isZoomed)
                Positioned(
                  left: 20,
                  bottom: 24,
                  child: _buildResetZoomButton(),
                ),
              if (!_won && !_dead)
                Positioned(
                  right: 20,
                  bottom: 24,
                  child: _buildHintButton(),
                ),
              if (_won)
                StageCompletePanel(
                  stageNumber: widget.stageNumber,
                  onNext: widget.onNext,
                  onHome: widget.onHome,
                ),
              if (_dead)
                GameOverPanel(
                  stageNumber: widget.stageNumber,
                  onRetry: _restartStage,
                  onHome: widget.onHome,
                  onWatchAd: widget.onRequestRewardRefill != null
                      ? _watchAdToRefill
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetZoomButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _resetZoom,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.surface,
            border: Border.all(color: AppPalette.textMuted, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 8),
            ],
          ),
          child: const Icon(Icons.zoom_out_map_rounded,
              color: AppPalette.textPrimary, size: 26),
        ),
      ),
    );
  }

  Widget _buildHintButton() {
    final hints = ref.watch(hintsProvider);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _useHint,
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.surface,
                border: Border.all(color: AppPalette.success, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.lightbulb_rounded,
                  color: AppPalette.success, size: 30),
            ),
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: hints > 0 ? AppPalette.success : AppPalette.danger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hints > 0 ? '$hints' : '+',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHud() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: widget.onHome,
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppPalette.textPrimary),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppPalette.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'STAGE ${widget.stageNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppPalette.textPrimary,
              ),
            ),
          ),
          Row(
            children: List.generate(widget.startingLives, (i) {
              final filled = i < _lives;
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  filled ? Icons.favorite : Icons.favorite_border,
                  color: filled ? AppPalette.danger : AppPalette.textMuted,
                  size: 26,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
