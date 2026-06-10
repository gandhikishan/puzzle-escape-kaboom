/// Offline level-generation tool.
///
/// Run from the project root:
///   dart run tool/generate_levels.dart [count]
///
/// Produces `assets/levels/levels.json` containing [count] (default 1200)
/// guaranteed-solvable, de-duplicated stages on a rising difficulty curve.
/// This runs once at build time; the app ships the resulting JSON and never
/// generates levels at runtime, so there is zero server cost.
library;

import 'dart:convert';
import 'dart:io';

import 'package:bombs_and_puzzles/levels/generator.dart';
import 'package:bombs_and_puzzles/levels/level.dart';
import 'package:bombs_and_puzzles/levels/solver.dart';

void main(List<String> args) {
  final count = args.isNotEmpty ? int.parse(args[0]) : 1200;

  final seen = <String>{};
  final levels = <Level>[];
  var seed = 1000;

  // For each stage we generate several unique candidates and then pick the one
  // whose measured difficulty matches the intended progression band. This is
  // what makes later stages genuinely tougher rather than just bigger.
  const candidateTarget = 16;
  const maxTriesPerStage = 600;

  for (var stage = 1; stage <= count; stage++) {
    final spec = difficultyForStage(stage);
    final candidates = <Level>[];
    final candidateSigs = <String>{};

    var tries = 0;
    while (candidates.length < candidateTarget && tries < maxTriesPerStage) {
      tries++;
      final candidate = LevelGenerator(seed++).generate(id: stage, spec: spec);
      if (candidate == null) continue;
      final signature = candidate.signature();
      if (seen.contains(signature) || candidateSigs.contains(signature)) {
        continue;
      }
      candidateSigs.add(signature);
      candidates.add(candidate);
    }

    if (candidates.isEmpty) {
      stderr.writeln('ERROR: could not generate a unique stage $stage');
      exit(1);
    }

    // Sort candidates easy -> hard and pick by the stage's target band.
    candidates.sort(
      (a, b) => computeMetrics(a).score.compareTo(computeMetrics(b).score),
    );
    final p = targetDifficultyFraction(stage);
    final pick = (p * (candidates.length - 1)).round();
    final chosen = candidates[pick];

    seen.add(chosen.signature());
    levels.add(chosen);

    if (stage % 100 == 0) {
      final m = computeMetrics(chosen);
      stdout.writeln('  ...stage $stage  '
          'grid ${chosen.width}x${chosen.height}  bombs ${chosen.bombCount}  '
          'difficulty ${m.score.toStringAsFixed(2)}');
    }
  }

  final payload = {
    'version': 1,
    'count': levels.length,
    'levels': levels.map((l) => l.toJson()).toList(),
  };

  final file = File('assets/levels/levels.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(payload));

  final sizeKb = (file.lengthSync() / 1024).toStringAsFixed(1);
  stdout.writeln('Wrote ${levels.length} unique levels '
      '(${sizeKb}KB) to ${file.path}');
}
