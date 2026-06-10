import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/game_sound.dart';
import '../levels/level.dart';
import 'board_background.dart';
import 'bomb_component.dart';
import 'explosion.dart';

typedef SoundCallback = void Function(GameSound sound);

/// The Flame game driving a single stage.
///
/// Game state (which cells are occupied) lives here; [BombComponent]s are pure
/// visuals that report taps back via [onBombTapped]. The widget layer listens
/// through the [onWin] and [onLifeLost] callbacks.
class BombGame extends FlameGame {
  BombGame({
    required this.onWin,
    required this.onLifeLost,
    this.onSound,
  });

  final VoidCallback onWin;
  final VoidCallback onLifeLost;
  final SoundCallback? onSound;

  Level? _level;
  late List<List<BombComponent?>> _grid;
  int _remaining = 0;
  bool _active = false;

  final PositionComponent _layer = PositionComponent();

  double _shakeTime = 0;
  double _shakeMagnitude = 0;
  final Random _rng = Random();

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await add(_layer);
    final pending = _level;
    if (pending != null) {
      _build(pending);
    }
  }

  /// Loads (or reloads) a stage. Safe to call before or after [onLoad].
  void loadLevel(Level level) {
    _level = level;
    if (isLoaded) {
      _build(level);
    }
  }

  void _build(Level level) {
    _layer.removeWhere((_) => true);
    _layer.position = Vector2.zero();
    _shakeTime = 0;

    _grid = List.generate(
      level.height,
      (_) => List<BombComponent?>.filled(level.width, null),
    );
    _remaining = level.bombs.length;
    _active = true;

    final layout = _computeLayout(level);

    _layer.add(BoardBackground(
      columns: level.width,
      rows: level.height,
      cellSize: layout.cell,
      origin: layout.origin,
    ));

    for (final bomb in level.bombs) {
      final center = Vector2(
        layout.origin.x + (bomb.x + 0.5) * layout.cell,
        layout.origin.y + (bomb.y + 0.5) * layout.cell,
      );
      final component = BombComponent(
        gridX: bomb.x,
        gridY: bomb.y,
        direction: bomb.direction,
        cellSize: layout.cell,
        center: center,
      );
      _grid[bomb.y][bomb.x] = component;
      _layer.add(component);
    }
  }

  _Layout _computeLayout(Level level) {
    final padding = 16.0;
    final available = Vector2(
      size.x - padding * 2,
      size.y - padding * 2,
    );
    final cell = min(
      available.x / level.width,
      available.y / level.height,
    );
    final boardWidth = cell * level.width;
    final boardHeight = cell * level.height;
    final origin = Vector2(
      (size.x - boardWidth) / 2,
      (size.y - boardHeight) / 2,
    );
    return _Layout(cell, origin);
  }

  void onBombTapped(BombComponent bomb) {
    if (!_active || bomb.launching) return;

    if (_hasClearPath(bomb)) {
      _launch(bomb);
    } else {
      _collide(bomb);
    }
  }

  bool _hasClearPath(BombComponent bomb) {
    final dir = bomb.direction;
    var cx = bomb.gridX + dir.dx;
    var cy = bomb.gridY + dir.dy;
    final level = _level!;
    while (cx >= 0 && cx < level.width && cy >= 0 && cy < level.height) {
      if (_grid[cy][cx] != null) return false;
      cx += dir.dx;
      cy += dir.dy;
    }
    return true;
  }

  void _launch(BombComponent bomb) {
    bomb.launching = true;
    _grid[bomb.gridY][bomb.gridX] = null;
    onSound?.call(GameSound.tap);

    final target = _edgePoint(bomb.position, bomb.direction);
    final distance = bomb.position.distanceTo(target);
    final duration = (distance / 1000).clamp(0.12, 0.5);

    bomb.add(
      MoveToEffect(
        target,
        EffectController(duration: duration, curve: Curves.easeIn),
        onComplete: () => _onBombExited(bomb, target),
      ),
    );
  }

  void _onBombExited(BombComponent bomb, Vector2 at) {
    onSound?.call(GameSound.explode);
    for (final c in buildExplosion(at, 1.0)) {
      _layer.add(c);
    }
    _shake(6);
    bomb.removeFromParent();

    _remaining--;
    if (_remaining <= 0 && _active) {
      _active = false;
      onSound?.call(GameSound.win);
      onWin();
    }
  }

  void _collide(BombComponent bomb) {
    onSound?.call(GameSound.collide);
    bomb.triggerCollisionFlash();
    _shake(12);
    onLifeLost();
  }

  Vector2 _edgePoint(Vector2 start, BombDirection dir) {
    var t = double.infinity;
    if (dir.dx > 0) {
      t = min(t, (size.x - start.x) / dir.dx);
    } else if (dir.dx < 0) {
      t = min(t, (0 - start.x) / dir.dx);
    }
    if (dir.dy > 0) {
      t = min(t, (size.y - start.y) / dir.dy);
    } else if (dir.dy < 0) {
      t = min(t, (0 - start.y) / dir.dy);
    }
    if (!t.isFinite || t < 0) t = 0;
    return Vector2(start.x + dir.dx * t, start.y + dir.dy * t);
  }

  void _shake(double magnitude) {
    _shakeMagnitude = magnitude;
    _shakeTime = 0.32;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shakeTime > 0) {
      _shakeTime -= dt;
      final falloff = (_shakeTime / 0.32).clamp(0.0, 1.0);
      final m = _shakeMagnitude * falloff;
      _layer.position = Vector2(
        (_rng.nextDouble() * 2 - 1) * m,
        (_rng.nextDouble() * 2 - 1) * m,
      );
      if (_shakeTime <= 0) {
        _layer.position = Vector2.zero();
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final level = _level;
    if (level != null && isLoaded && _active) {
      _build(level);
    }
  }
}

class _Layout {
  const _Layout(this.cell, this.origin);
  final double cell;
  final Vector2 origin;
}
