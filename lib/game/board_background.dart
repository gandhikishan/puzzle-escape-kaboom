import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../core/app_palette.dart';

/// Draws the grid of empty tiles behind the bombs. Purely cosmetic.
class BoardBackground extends PositionComponent {
  BoardBackground({
    required this.columns,
    required this.rows,
    required this.cellSize,
    required Vector2 origin,
  }) {
    position = origin;
    size = Vector2(columns * cellSize, rows * cellSize);
  }

  final int columns;
  final int rows;
  final double cellSize;

  @override
  void render(Canvas canvas) {
    const inset = 3.0;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        final isAlt = (x + y).isEven;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x * cellSize + inset,
            y * cellSize + inset,
            cellSize - inset * 2,
            cellSize - inset * 2,
          ),
          const Radius.circular(10),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..color = isAlt ? AppPalette.boardCell : AppPalette.boardCellAlt,
        );
      }
    }
  }
}
