import 'package:flutter_test/flutter_test.dart';

import 'package:bombs_and_puzzles/levels/generator.dart';
import 'package:bombs_and_puzzles/levels/level.dart';
import 'package:bombs_and_puzzles/levels/solver.dart';

void main() {
  group('generator', () {
    test('produces solvable stages across the difficulty curve', () {
      final gen = LevelGenerator(42);
      for (final stage in [1, 25, 100, 300, 600, 1000]) {
        final level = gen.generate(id: stage, spec: difficultyForStage(stage));
        expect(level, isNotNull, reason: 'stage $stage failed to generate');
        expect(isSolvable(level!), isTrue, reason: 'stage $stage unsolvable');
      }
    });

    test('difficulty rises with stage number', () {
      final early = difficultyForStage(1);
      final late = difficultyForStage(1000);
      expect(late.width >= early.width, isTrue);
      expect(late.height >= early.height, isTrue);
      expect(late.targetBombs > early.targetBombs, isTrue);
    });
  });

  group('solver', () {
    test('detects an unsolvable deadlock', () {
      // Two bombs pointing into each other: neither can ever leave.
      final level = Level(
        id: 1,
        width: 3,
        height: 1,
        bombs: const [
          Bomb(x: 0, y: 0, direction: BombDirection.right),
          Bomb(x: 2, y: 0, direction: BombDirection.left),
        ],
      );
      expect(isSolvable(level), isFalse);
    });

    test('round-trips through JSON', () {
      final gen = LevelGenerator(7);
      final level = gen.generate(id: 5, spec: difficultyForStage(5))!;
      final restored = Level.fromJson(level.toJson());
      expect(restored.signature(), level.signature());
    });
  });
}
