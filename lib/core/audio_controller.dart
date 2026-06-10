import 'package:flame_audio/flame_audio.dart';

import 'game_sound.dart';

/// Loads and plays the game's short sound effects.
///
/// Kept independent of widgets/state so it can be owned by the play flow and
/// muted via [enabled] based on the user's settings.
class AudioController {
  bool enabled = true;
  bool _ready = false;

  static const _files = {
    GameSound.tap: 'tap.wav',
    GameSound.explode: 'explode.wav',
    GameSound.collide: 'collide.wav',
    GameSound.win: 'win.wav',
  };

  Future<void> init() async {
    if (_ready) return;
    await FlameAudio.audioCache.loadAll(_files.values.toList());
    _ready = true;
  }

  void play(GameSound sound) {
    if (!enabled || !_ready) return;
    final file = _files[sound];
    if (file == null) return;
    final volume = sound == GameSound.tap ? 0.4 : 0.7;
    FlameAudio.play(file, volume: volume);
  }

  void dispose() {
    FlameAudio.audioCache.clearAll();
    _ready = false;
  }
}
