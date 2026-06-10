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

  /// The canvas size the current board was laid out for. Used to detect the
  /// transient-size-then-final-size sequence Flutter produces during the first
  /// layout passes, so we re-lay-out once the real size arrives.
  Vector2? _builtSize;

  final PositionComponent _layer = PositionComponent();

  double _shakeTime = 0;
  double _shakeMagnitude = 0;
  final Random _rng = Random();

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await add(_layer);
    // The actual stage build happens in update() once the canvas reports a
    // usable size and the layer is mounted.
  }

  /// Loads (or reloads) a stage. Safe to call before or after [onLoad].
  void loadLevel(Level level) {
    _level = level;
    _builtSize = null;
    if (isLoaded && _hasUsableSize && _layer.isMounted) {
      _build(level);
    }
  }

  bool get _hasUsableSize => size.x > 8 && size.y > 8;

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
    _builtSize = size.clone();

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
        path: bomb.path,
        routeOffsets:
            bomb.isCurved ? _routeOffsets(bomb, layout, center) : null,
      );
      _grid[bomb.y][bomb.x] = component;
      _layer.add(component);
    }
  }

  /// World-space points (as offsets from [center]) that a curved bomb travels
  /// through, ending just off the board edge.
  List<Vector2> _routeOffsets(Bomb bomb, _Layout layout, Vector2 center) {
    final points = <Vector2>[];
    var cx = bomb.x;
    var cy = bomb.y;
    for (final step in bomb.path!) {
      cx += step.dx;
      cy += step.dy;
      final world = Vector2(
        layout.origin.x + (cx + 0.5) * layout.cell,
        layout.origin.y + (cy + 0.5) * layout.cell,
      );
      points.add(world - center);
      final level = _level!;
      if (cx < 0 || cx >= level.width || cy < 0 || cy >= level.height) {
        break; // this point is the off-board exit
      }
    }
    return points;
  }

  _Layout _computeLayout(Level level) {
    const padding = 24.0;
    // Cap the cell size so the board stays compact (smaller grid) instead of
    // stretching edge-to-edge. The player pinch-zooms in to tap precisely.
    const maxCell = 92.0;
    final available = Vector2(
      size.x - padding * 2,
      size.y - padding * 2,
    );
    final cell = min(
      maxCell,
      min(
        available.x / level.width,
        available.y / level.height,
      ),
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

  /// Highlights one bomb that currently has a clear path. Returns false if the
  /// board is not in a playable state (nothing to hint).
  bool showHint() {
    if (!_active) return false;
    final level = _level;
    if (level == null) return false;
    for (var y = 0; y < level.height; y++) {
      for (var x = 0; x < level.width; x++) {
        final bomb = _grid[y][x];
        if (bomb != null && !bomb.launching && _hasClearPath(bomb)) {
          bomb.triggerHint();
          return true;
        }
      }
    }
    return false;
  }

  bool _hasClearPath(BombComponent bomb) {
    final level = _level!;
    if (bomb.path != null) {
      var cx = bomb.gridX;
      var cy = bomb.gridY;
      for (final step in bomb.path!) {
        cx += step.dx;
        cy += step.dy;
        if (cx < 0 || cx >= level.width || cy < 0 || cy >= level.height) {
          return true; // exited the board
        }
        if (_grid[cy][cx] != null) return false;
      }
      return true;
    }

    final dir = bomb.direction;
    var cx = bomb.gridX + dir.dx;
    var cy = bomb.gridY + dir.dy;
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

    if (bomb.isCurved && bomb.routeOffsets != null) {
      final offsets = bomb.routeOffsets!;
      final path = Path()..moveTo(0, 0);
      var length = 0.0;
      var prev = Vector2.zero();
      for (final o in offsets) {
        path.lineTo(o.x, o.y);
        length += (o - prev).length;
        prev = o;
      }
      final exit = bomb.position + offsets.last;
      final duration = (length / 900).clamp(0.18, 0.9);
      bomb.add(
        MoveAlongPathEffect(
          path,
          EffectController(duration: duration, curve: Curves.easeIn),
          onComplete: () => _onBombExited(bomb, exit),
        ),
      );
      return;
    }

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

    // Build (or re-lay-out) the stage whenever the canvas reports a new usable
    // size. The first layout passes can report a transient tiny size, so we
    // rebuild once the real size settles. Guarded so an in-progress board is
    // only re-laid-out on an actual size change, not every frame.
    final level = _level;
    if (level != null && _layer.isMounted && _hasUsableSize) {
      final built = _builtSize;
      if (built == null || (built.x - size.x).abs() > 1 ||
          (built.y - size.y).abs() > 1) {
        _build(level);
      }
    }

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

}

class _Layout {
  const _Layout(this.cell, this.origin);
  final double cell;
  final Vector2 origin;
}
