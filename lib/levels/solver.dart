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

  /// True when [bomb] can travel its full route off the board without hitting
  /// another occupied cell. Handles both straight and curved bombs.
  bool hasClearRoute(Bomb bomb) {
    if (!bomb.isCurved) {
      return hasClearPath(bomb.x, bomb.y, bomb.direction);
    }
    var cx = bomb.x;
    var cy = bomb.y;
    for (final step in bomb.path!) {
      cx += step.dx;
      cy += step.dy;
      if (!inBounds(cx, cy)) return true; // left the board => exited cleanly
      if (occupied(cx, cy)) return false;
    }
    // A well-formed curved route always ends off-board; if it somehow doesn't,
    // treat the final cell as the exit.
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
      if (grid.hasClearRoute(bomb)) {
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

/// Quantified difficulty of a board, derived by replaying the greedy solution.
class SolveMetrics {
  const SolveMetrics({
    required this.solvable,
    required this.avgBlocked,
    required this.forcedFraction,
    required this.diagonalFraction,
    required this.curvedFraction,
  });

  final bool solvable;

  /// Average number of currently-blocked bombs present at each solve step.
  /// A blocked bomb is a mis-tap waiting to happen, so more = riskier = harder.
  final double avgBlocked;

  /// Fraction of steps where exactly one bomb had a clear path. High values
  /// mean the player must find the single safe move (a forced chain).
  final double forcedFraction;

  /// Fraction of bombs that travel diagonally (harder to trace visually).
  final double diagonalFraction;

  /// Fraction of bombs that follow a curved route (harder to read at a glance).
  final double curvedFraction;

  /// Single 0..~N difficulty score combining the factors above.
  double get score =>
      avgBlocked +
      forcedFraction * 2.0 +
      diagonalFraction * 1.5 +
      curvedFraction * 2.0;
}

/// Replays the greedy solution to measure how risky/forced a board is.
SolveMetrics computeMetrics(Level level) {
  final grid = BoardGrid(level.width, level.height);
  for (final bomb in level.bombs) {
    grid.set(bomb.x, bomb.y, true);
  }

  final remaining = List<int>.generate(level.bombs.length, (i) => i);
  var totalBlocked = 0;
  var forcedSteps = 0;
  var steps = 0;

  while (remaining.isNotEmpty) {
    final clearIndices = <int>[];
    for (final index in remaining) {
      final bomb = level.bombs[index];
      if (grid.hasClearRoute(bomb)) {
        clearIndices.add(index);
      }
    }
    if (clearIndices.isEmpty) {
      return const SolveMetrics(
        solvable: false,
        avgBlocked: 0,
        forcedFraction: 0,
        diagonalFraction: 0,
        curvedFraction: 0,
      );
    }

    totalBlocked += remaining.length - clearIndices.length;
    if (clearIndices.length == 1) forcedSteps++;
    steps++;

    final removed = clearIndices.first;
    final bomb = level.bombs[removed];
    grid.set(bomb.x, bomb.y, false);
    remaining.remove(removed);
  }

  final diagonal =
      level.bombs.where((b) => b.direction.isDiagonal).length;
  final curved = level.bombs.where((b) => b.isCurved).length;

  return SolveMetrics(
    solvable: true,
    avgBlocked: steps == 0 ? 0 : totalBlocked / steps,
    forcedFraction: steps == 0 ? 0 : forcedSteps / steps,
    diagonalFraction:
        level.bombs.isEmpty ? 0 : diagonal / level.bombs.length,
    curvedFraction: level.bombs.isEmpty ? 0 : curved / level.bombs.length,
  );
}
