import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bombs_and_puzzles/levels/level.dart';
import 'package:bombs_and_puzzles/levels/solver.dart';

/// Validates the shipped asset directly from disk so a bad generation run can
/// never reach players.
void main() {
  test('bundled levels.json is present, unique and fully solvable', () {
    final file = File('assets/levels/levels.json');
    expect(file.existsSync(), isTrue,
        reason: 'run: dart run tool/generate_levels.dart');

    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final levels = (data['levels'] as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList();

    expect(levels.length, greaterThanOrEqualTo(1000),
        reason: 'need 1000+ stages');

    final signatures = <String>{};
    for (final level in levels) {
      expect(isSolvable(level), isTrue,
          reason: 'stage ${level.id} is not solvable');
      final added = signatures.add(level.signature());
      expect(added, isTrue, reason: 'duplicate layout at stage ${level.id}');
    }
  });
}
