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

void main(List<String> args) {
  final count = args.isNotEmpty ? int.parse(args[0]) : 1200;

  final seen = <String>{};
  final levels = <Level>[];
  var seed = 1000;
  const maxTriesPerStage = 400;

  for (var stage = 1; stage <= count; stage++) {
    final spec = difficultyForStage(stage);
    Level? chosen;

    for (var tries = 0; tries < maxTriesPerStage; tries++) {
      final candidate = LevelGenerator(seed++).generate(id: stage, spec: spec);
      if (candidate == null) continue;
      final signature = candidate.signature();
      if (seen.contains(signature)) continue;
      seen.add(signature);
      chosen = candidate;
      break;
    }

    if (chosen == null) {
      stderr.writeln('ERROR: could not generate a unique stage $stage');
      exit(1);
    }
    levels.add(chosen);

    if (stage % 100 == 0) {
      stdout.writeln('  ...generated $stage / $count');
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
