import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../core/app_palette.dart';
import '../levels/level.dart';
import 'bomb_game.dart';

/// A single tappable bomb rendered on the board.
///
/// Drawing is done directly on the canvas (no image assets required) so the
/// game ships small and stays fully procedural.
class BombComponent extends PositionComponent
    with TapCallbacks, HasGameReference<BombGame> {
  BombComponent({
    required this.gridX,
    required this.gridY,
    required this.direction,
    required double cellSize,
    required Vector2 center,
  }) {
    size = Vector2.all(cellSize);
    anchor = Anchor.center;
    position = center;
  }

  final int gridX;
  final int gridY;
  final BombDirection direction;

  /// Set true the moment a bomb starts leaving so further taps ignore it.
  bool launching = false;

  double _flash = 0;

  void triggerCollisionFlash() {
    _flash = 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flash > 0) {
      _flash = max(0, _flash - dt * 3.0);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.onBombTapped(this);
  }

  @override
  void render(Canvas canvas) {
    final s = size.x;
    final radius = s * 0.34;
    final center = Offset(s / 2, s / 2);

    // Soft drop shadow grounds the bomb on the tile.
    canvas.drawCircle(
      center.translate(0, radius * 0.22),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Body.
    final bodyPaint = Paint()..color = AppPalette.bombBody;
    canvas.drawCircle(center, radius, bodyPaint);

    // Glossy highlight.
    canvas.drawCircle(
      center.translate(-radius * 0.32, -radius * 0.34),
      radius * 0.3,
      Paint()..color = AppPalette.bombHighlight.withValues(alpha: 0.8),
    );

    // Fuse spark at the top.
    final sparkPaint = Paint()..color = AppPalette.accentSecondary;
    canvas.drawCircle(center.translate(0, -radius * 1.05), radius * 0.14,
        sparkPaint);
    canvas.drawCircle(
      center.translate(0, -radius * 1.05),
      radius * 0.26,
      Paint()..color = AppPalette.accent.withValues(alpha: 0.4),
    );

    _drawArrow(canvas, center, radius);

    if (_flash > 0) {
      canvas.drawCircle(
        center,
        radius * (1 + _flash * 0.4),
        Paint()
          ..color = AppPalette.danger.withValues(alpha: _flash * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  void _drawArrow(Canvas canvas, Offset center, double radius) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(direction.angle);

    final arrowPaint = Paint()..color = AppPalette.accentSecondary;
    final path = Path();
    final tip = -radius * 0.55;
    final tail = radius * 0.35;
    final halfW = radius * 0.42;

    // Arrowhead pointing "up" before rotation.
    path.moveTo(0, tip);
    path.lineTo(halfW, tip + halfW);
    path.lineTo(halfW * 0.4, tip + halfW);
    path.lineTo(halfW * 0.4, tail);
    path.lineTo(-halfW * 0.4, tail);
    path.lineTo(-halfW * 0.4, tip + halfW);
    path.lineTo(-halfW, tip + halfW);
    path.close();

    canvas.drawPath(path, arrowPaint);
    canvas.restore();
  }
}
