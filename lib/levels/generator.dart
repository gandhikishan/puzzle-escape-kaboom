/// Reverse-construction level generator.
///
/// Boards are built center-out: cells are filled from the middle of the grid
/// outward. Each bomb is given a route (straight or curved) whose path to the
/// edge runs only through cells that are still empty at placement time, so the
/// reverse of the placement order is always a valid solution. This lets us pack
/// nearly every cell with a bomb while keeping every stage guaranteed solvable.
library;

import 'dart:math';

import 'level.dart';
import 'solver.dart';

/// Difficulty parameters for a single stage, derived from its index.
class DifficultySpec {
  const DifficultySpec({
    required this.width,
    required this.height,
    required this.diagonalChance,
    required this.curveChance,
    required this.emptyCells,
  });

  final int width;
  final int height;

  /// Probability that a straight bomb is allowed to use a diagonal direction.
  final double diagonalChance;

  /// Probability that a bomb is given a curved (bending) route.
  final double curveChance;

  /// How many cells are left empty (the board is otherwise packed full).
  final int emptyCells;
}

/// Maps a 1-based stage number onto a rising difficulty curve.
///
/// Grid size grows steadily from stage 2; the board is then packed almost full
/// with bombs (only [DifficultySpec.emptyCells] left open). Diagonals and curved
/// routes are layered in as stages progress for extra spectacle and challenge.
DifficultySpec difficultyForStage(int stage) {
  final t = (stage - 1).toDouble();
  final r = sqrt(t);

  final width = (3 + r / 2.0).floor().clamp(3, 8);
  final height = (3 + r).floor().clamp(3, 12);
  final cells = width * height;

  final diagonalChance =
      stage < 25 ? 0.0 : ((stage - 25) * 0.0016).clamp(0.0, 0.5);

  // Curved bombs appear from ~stage 15 and become common by the mid game.
  final curveChance =
      stage < 15 ? 0.0 : ((stage - 15) * 0.0011).clamp(0.0, 0.4);

  // Pack the board: leave only one or two empty cells.
  final emptyCells = cells <= 12 ? 1 : 2;

  return DifficultySpec(
    width: width,
    height: height,
    diagonalChance: diagonalChance,
    curveChance: curveChance,
    emptyCells: emptyCells,
  );
}

/// Where on the easy(0)..hard(1) band a stage should sit. Used to pick, among
/// several candidate boards, one whose measured difficulty matches the intended
/// progression. Early stages favour easy boards; by ~stage 750 we always pick
/// the hardest candidate generated.
double targetDifficultyFraction(int stage) {
  return ((stage - 1) / 750.0).clamp(0.0, 1.0);
}

class LevelGenerator {
  LevelGenerator(int seed) : _rng = Random(seed);

  final Random _rng;

  /// Attempts to build a packed, solvable stage [id] matching [spec].
  Level? generate({required int id, required DifficultySpec spec}) {
    final w = spec.width;
    final h = spec.height;
    final grid = BoardGrid(w, h);

    int depthOf(int x, int y) => min(min(x, w - 1 - x), min(y, h - 1 - y));

    // All cells, minus a handful left intentionally empty.
    final allCells = <Point<int>>[
      for (var y = 0; y < h; y++)
        for (var x = 0; x < w; x++) Point(x, y),
    ];
    final emptySet = <Point<int>>{};
    final shuffledForEmpty = [...allCells]..shuffle(_rng);
    for (var i = 0; i < spec.emptyCells && i < shuffledForEmpty.length; i++) {
      emptySet.add(shuffledForEmpty[i]);
    }

    // Placement order: deepest (center) cells first. Reverse of this order is
    // the solution (peel from the outside in).
    final placement = allCells.where((c) => !emptySet.contains(c)).toList()
      ..shuffle(_rng)
      ..sort((a, b) => depthOf(b.x, b.y).compareTo(depthOf(a.x, a.y)));

    final bombs = <Bomb>[];
    for (final cell in placement) {
      List<BombDirection>? path;
      if (_rng.nextDouble() < spec.curveChance) {
        path = _tryCurve(grid, cell.x, cell.y, w, h);
      }

      final BombDirection dir;
      if (path != null) {
        dir = path.first;
      } else {
        dir = _chooseStraightDir(grid, cell.x, cell.y, w, h, spec);
      }

      grid.set(cell.x, cell.y, true);
      bombs.add(Bomb(x: cell.x, y: cell.y, direction: dir, path: path));
    }

    if (bombs.length < 3) return null;

    final level = Level(id: id, width: w, height: h, bombs: bombs);
    if (!isSolvable(level)) return null;
    return level;
  }

  /// Directions pointing toward the nearest board edge (always a clear exit).
  List<BombDirection> _nearestBorderDirs(int x, int y, int w, int h) {
    final dl = x, dr = w - 1 - x, du = y, dd = h - 1 - y;
    final m = min(min(dl, dr), min(du, dd));
    return <BombDirection>[
      if (dl == m) BombDirection.left,
      if (dr == m) BombDirection.right,
      if (du == m) BombDirection.up,
      if (dd == m) BombDirection.down,
    ];
  }

  BombDirection _chooseStraightDir(
      BoardGrid grid, int x, int y, int w, int h, DifficultySpec spec) {
    final allowDiagonal = _rng.nextDouble() < spec.diagonalChance;
    final candidates = <BombDirection>[
      ...BombDirection.cardinals,
      if (allowDiagonal) ...BombDirection.diagonals,
    ]..shuffle(_rng);

    for (final dir in candidates) {
      if (grid.hasClearPath(x, y, dir)) return dir;
    }
    // The nearest-border cardinal is always clear under center-out placement.
    return (_nearestBorderDirs(x, y, w, h)..shuffle(_rng)).first;
  }

  /// Builds a bending route (outward, then a sidestep, then out to the edge)
  /// through currently-empty cells. Returns null if no valid bend was found.
  List<BombDirection>? _tryCurve(BoardGrid grid, int x, int y, int w, int h) {
    final outwardOptions = _nearestBorderDirs(x, y, w, h)..shuffle(_rng);
    for (final p in outwardOptions) {
      final laterals = (p == BombDirection.up || p == BombDirection.down)
          ? <BombDirection>[BombDirection.left, BombDirection.right]
          : <BombDirection>[BombDirection.up, BombDirection.down];
      laterals.shuffle(_rng);
      for (final l in laterals) {
        final lateralSteps = 1 + _rng.nextInt(2); // 1 or 2 sidesteps
        final maneuver = <BombDirection>[p, for (var i = 0; i < lateralSteps; i++) l];
        final route = _walkRoute(grid, x, y, maneuver, p, w, h);
        if (route != null && route.length >= 2) {
          return route;
        }
      }
    }
    return null;
  }

  /// Walks [maneuver] from the start cell, then continues in [finalDir] until
  /// the route leaves the board. Returns the full step list, or null if any
  /// in-board cell along the way is occupied.
  List<BombDirection>? _walkRoute(BoardGrid grid, int x, int y,
      List<BombDirection> maneuver, BombDirection finalDir, int w, int h) {
    final steps = <BombDirection>[];
    var cx = x, cy = y;

    for (final d in maneuver) {
      steps.add(d);
      final nx = cx + d.dx, ny = cy + d.dy;
      if (!grid.inBounds(nx, ny)) return steps; // exited during the bend
      if (grid.occupied(nx, ny)) return null;
      cx = nx;
      cy = ny;
    }

    var guard = 0;
    final limit = w + h + 4;
    while (guard++ < limit) {
      steps.add(finalDir);
      final nx = cx + finalDir.dx, ny = cy + finalDir.dy;
      if (!grid.inBounds(nx, ny)) return steps; // reached the edge and exited
      if (grid.occupied(nx, ny)) return null;
      cx = nx;
      cy = ny;
    }
    return null;
  }
}
