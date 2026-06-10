import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio_controller.dart';
import '../levels/level.dart';
import '../state/providers.dart';
import 'game_screen.dart';

/// Host/controller for the play session. It pulls the level for the player's
/// current stage from the repository, renders the single [GameScreen], and
/// handles progression + audio. Monetization hooks are layered in here in a
/// later milestone so [GameScreen] itself stays presentation-only.
class PlayRoute extends ConsumerStatefulWidget {
  const PlayRoute({super.key});

  @override
  ConsumerState<PlayRoute> createState() => _PlayRouteState();
}

class _PlayRouteState extends ConsumerState<PlayRoute> {
  final AudioController _audio = AudioController();
  int _lastLoggedStage = -1;

  @override
  void initState() {
    super.initState();
    _audio.init();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final settings = ref.watch(settingsProvider);
    _audio.enabled = settings.soundOn;

    final repository = ref.read(levelRepositoryProvider);
    final ads = ref.read(adsServiceProvider);
    final firebase = ref.read(firebaseServiceProvider);
    final stage = progress.currentStage;
    final Level level = repository.levelForStage(stage);

    if (_lastLoggedStage != stage) {
      _lastLoggedStage = stage;
      firebase.logStageStarted(stage);
    }

    return GameScreen(
      key: ValueKey(stage),
      level: level,
      stageNumber: stage,
      startingLives: firebase.livesPerStage,
      onSound: _audio.play,
      onStageCleared: () => firebase.logStageCleared(stage),
      onGameOver: () => firebase.logGameOver(stage),
      onNext: () {
        ads.onStageCleared();
        ref.read(progressProvider.notifier).advance();
      },
      onHome: () => Navigator.of(context).maybePop(),
      onRequestRewardRefill: ads.showRewarded,
    );
  }
}
