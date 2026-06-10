import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'level.dart';

/// Loads the bundled, pre-generated stages from `assets/levels/levels.json`.
///
/// The game is fully offline: levels are generated once at build time (see
/// `tool/generate_levels.dart`) and read from the app bundle here. If a player
/// somehow exceeds the bundled count, stages wrap so play never ends.
class LevelRepository {
  static const String _assetPath = 'assets/levels/levels.json';

  List<Level>? _levels;

  bool get isLoaded => _levels != null;

  int get count => _levels?.length ?? 0;

  Future<void> ensureLoaded() async {
    if (_levels != null) return;
    final raw = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _levels = (data['levels'] as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Returns the [Level] for a 1-based [stage] number, wrapping if needed.
  Level levelForStage(int stage) {
    final levels = _levels;
    if (levels == null || levels.isEmpty) {
      throw StateError('LevelRepository.ensureLoaded() must be called first');
    }
    final index = (stage - 1) % levels.length;
    return levels[index];
  }
}
