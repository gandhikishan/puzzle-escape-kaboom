/// Greedy solver and path utilities for Bombs and Puzzles boards.
///
/// Core property of the mechanic: removing a bomb only ever frees cells, so it
/// can never block another bomb. A board is therefore solvable iff, at every
/// state, at least one remaining bomb has a clear path off the grid.
library;

import 'level.dart';

/// Mutable occupancy grid used during solving/generation.
class BoardGrid {
  BoardGrid(this.width, this.height)
      : _cells = List<bool>.filled(width * height, false);

  final int width;
  final int height;
  final List<bool> _cells;

  bool occupied(int x, int y) => _cells[y * width + x];

  void set(int x, int y, bool value) => _cells[y * width + x] = value;

  bool inBounds(int x, int y) =>
      x >= 0 && x < width && y >= 0 && y < height;

  /// True when nothing blocks the bomb at ([x],[y]) from leaving in [dir].
  bool hasClearPath(int x, int y, BombDirection dir) {
    var cx = x + dir.dx;
    var cy = y + dir.dy;
    while (inBounds(cx, cy)) {
      if (occupied(cx, cy)) return false;
      cx += dir.dx;
      cy += dir.dy;
    }
    return true;
  }
}

/// Returns a valid removal order for [level], or `null` if it is unsolvable.
///
/// Deterministic: scans bombs in a fixed order each round so results are
/// reproducible for tests and validation.
List<int>? solve(Level level) {
  final grid = BoardGrid(level.width, level.height);
  for (final bomb in level.bombs) {
    grid.set(bomb.x, bomb.y, true);
  }

  final remaining = List<int>.generate(level.bombs.length, (i) => i);
  final order = <int>[];

  while (remaining.isNotEmpty) {
    var removedThisRound = false;
    for (var i = 0; i < remaining.length; i++) {
      final index = remaining[i];
      final bomb = level.bombs[index];
      if (grid.hasClearPath(bomb.x, bomb.y, bomb.direction)) {
        grid.set(bomb.x, bomb.y, false);
        order.add(index);
        remaining.removeAt(i);
        removedThisRound = true;
        break;
      }
    }
    if (!removedThisRound) return null;
  }
  return order;
}

bool isSolvable(Level level) => solve(level) != null;
