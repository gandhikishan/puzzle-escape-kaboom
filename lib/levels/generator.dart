/// Reverse-construction level generator.
///
/// Builds a board by adding one bomb at a time onto an empty grid; each bomb is
/// only placed in a direction whose path to the edge is currently clear. The
/// reverse of the insertion order is therefore always a valid solution, which
/// guarantees every generated stage is solvable without an expensive search.
library;

import 'dart:math';

import 'level.dart';
import 'solver.dart';

/// Difficulty parameters for a single stage, derived from its index.
class DifficultySpec {
  const DifficultySpec({
    required this.width,
    required this.height,
    required this.targetBombs,
    required this.diagonalChance,
  });

  final int width;
  final int height;
  final int targetBombs;

  /// Probability that a placed bomb is allowed to use a diagonal direction.
  final double diagonalChance;
}

/// Maps a 1-based stage number onto a smoothly rising difficulty curve.
///
/// Grid size, bomb density and diagonal usage all increase with progression so
/// the first stages act as a gentle tutorial and later stages get dense and
/// chaotic.
DifficultySpec difficultyForStage(int stage) {
  final t = (stage - 1).toDouble();

  // Grid grows from 3x3 up to a portrait-friendly 7x9.
  final width = (3 + (t / 90)).floor().clamp(3, 7);
  final height = (3 + (t / 70)).floor().clamp(3, 9);

  final cells = width * height;
  // Density ramps from ~35% of cells filled to ~70%.
  final density = (0.35 + t * 0.0006).clamp(0.35, 0.70);
  final targetBombs = max(3, (cells * density).round());

  // Diagonals are introduced around stage 60 and become common later.
  final diagonalChance = stage < 60 ? 0.0 : ((t - 60) * 0.004).clamp(0.0, 0.45);

  return DifficultySpec(
    width: width,
    height: height,
    targetBombs: targetBombs,
    diagonalChance: diagonalChance,
  );
}

class LevelGenerator {
  LevelGenerator(int seed) : _rng = Random(seed);

  final Random _rng;

  /// Attempts to build a solvable stage [id] matching [spec].
  ///
  /// Returns `null` only if it could not place enough bombs after many tries
  /// (the caller can simply retry with a fresh attempt).
  Level? generate({required int id, required DifficultySpec spec}) {
    final grid = BoardGrid(spec.width, spec.height);
    final bombs = <Bomb>[];

    final emptyCells = <Point<int>>[
      for (var y = 0; y < spec.height; y++)
        for (var x = 0; x < spec.width; x++) Point(x, y),
    ];

    var attempts = 0;
    final maxAttempts = spec.targetBombs * 40;

    while (bombs.length < spec.targetBombs && attempts < maxAttempts) {
      attempts++;
      if (emptyCells.isEmpty) break;

      final pick = _rng.nextInt(emptyCells.length);
      final cell = emptyCells[pick];

      final allowDiagonal = _rng.nextDouble() < spec.diagonalChance;
      final candidates = <BombDirection>[
        ...BombDirection.cardinals,
        if (allowDiagonal) ...BombDirection.diagonals,
      ]..shuffle(_rng);

      BombDirection? chosen;
      for (final dir in candidates) {
        if (grid.hasClearPath(cell.x, cell.y, dir)) {
          chosen = dir;
          break;
        }
      }
      if (chosen == null) continue;

      grid.set(cell.x, cell.y, true);
      bombs.add(Bomb(x: cell.x, y: cell.y, direction: chosen));
      emptyCells.removeAt(pick);
    }

    if (bombs.length < 3) return null;

    final level = Level(
      id: id,
      width: spec.width,
      height: spec.height,
      bombs: bombs,
    );

    // Safety net: the construction guarantees solvability, but we verify.
    if (!isSolvable(level)) return null;
    return level;
  }
}
