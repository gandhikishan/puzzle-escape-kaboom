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
    this.path,
    this.routeOffsets,
  }) {
    size = Vector2.all(cellSize);
    anchor = Anchor.center;
    position = center;
  }

  final int gridX;
  final int gridY;
  final BombDirection direction;

  /// Curved-route step list (null for straight bombs). Used for clear-path
  /// checks against the live grid.
  final List<BombDirection>? path;

  /// Points the bomb travels through, as offsets from the bomb's centre. The
  /// last entry is the off-board exit point. Null for straight bombs.
  final List<Vector2>? routeOffsets;

  bool get isCurved => path != null && path!.isNotEmpty;

  /// Set true the moment a bomb starts leaving so further taps ignore it.
  bool launching = false;

  double _flash = 0;
  double _hint = 0;

  void triggerCollisionFlash() {
    _flash = 1.0;
  }

  /// Pulses a positive highlight to point the player at a safe bomb.
  void triggerHint() {
    _hint = 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flash > 0) {
      _flash = max(0, _flash - dt * 3.0);
    }
    if (_hint > 0) {
      _hint = max(0, _hint - dt * 0.6);
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

    if (isCurved && routeOffsets != null && !launching) {
      _drawRoute(canvas, center, radius);
    }

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

    if (_hint > 0) {
      // Two pulsing success-colored rings to draw the eye.
      final pulse = (1 - _hint);
      canvas.drawCircle(
        center,
        radius * (1.05 + pulse * 0.5),
        Paint()
          ..color = AppPalette.success.withValues(alpha: _hint)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      canvas.drawCircle(
        center,
        radius * 1.05,
        Paint()..color = AppPalette.success.withValues(alpha: _hint * 0.18),
      );
    }
  }

  /// Draws the curved route as a translucent dotted trail with an arrowhead at
  /// the exit so the player can read where this bomb will travel.
  void _drawRoute(Canvas canvas, Offset center, double radius) {
    final offsets = routeOffsets!;
    final points = <Offset>[
      center,
      for (final o in offsets) center.translate(o.x, o.y),
    ];

    final trail = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      trail.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(
      trail,
      Paint()
        ..color = AppPalette.accent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.34
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Bend markers.
    for (var i = 1; i < points.length - 1; i++) {
      canvas.drawCircle(points[i], radius * 0.16,
          Paint()..color = AppPalette.accent.withValues(alpha: 0.7));
    }

    // Arrowhead at the exit, oriented along the final segment.
    final tipEnd = points.last;
    final prev = points[points.length - 2];
    final angle = atan2(tipEnd.dy - prev.dy, tipEnd.dx - prev.dx);
    const headLen = 0.0;
    final size = radius * 0.6;
    canvas.save();
    canvas.translate(tipEnd.dx, tipEnd.dy);
    canvas.rotate(angle);
    final head = Path()
      ..moveTo(headLen, 0)
      ..lineTo(-size * 0.7, size * 0.5)
      ..lineTo(-size * 0.7, -size * 0.5)
      ..close();
    canvas.drawPath(head, Paint()..color = AppPalette.accent);
    canvas.restore();
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
