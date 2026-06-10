import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_palette.dart';
import '../core/game_sound.dart';
import '../game/bomb_game.dart';
import '../game/overlays/result_panels.dart';
import '../levels/level.dart';

/// Renders and runs a single stage. Stage progression, persistence and ads are
/// owned by the caller via the callbacks below, keeping this screen focused on
/// play + in-stage life tracking. There is exactly one game screen in the app.
class GameScreen extends StatefulWidget {
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
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late BombGame _game;
  late int _lives;
  bool _won = false;
  bool _dead = false;

  @override
  void initState() {
    super.initState();
    _lives = widget.startingLives;
    _game = BombGame(
      onWin: _handleWin,
      onLifeLost: _handleLifeLost,
      onSound: widget.onSound,
    )..loadLevel(widget.level);
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
    _game.loadLevel(widget.level);
  }

  Future<void> _watchAdToRefill() async {
    final granted = await widget.onRequestRewardRefill?.call() ?? false;
    if (granted && mounted) {
      _restartStage();
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
            children: [
              Positioned.fill(child: GameWidget(game: _game)),
              _buildHud(),
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
