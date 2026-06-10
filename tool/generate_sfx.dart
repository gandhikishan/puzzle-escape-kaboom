/// Synthesizes the game's sound effects as small 16-bit PCM WAV files.
///
/// Run from the project root:
///   dart run tool/generate_sfx.dart
///
/// Generating audio procedurally keeps the repo free of licensed assets and the
/// download tiny. Outputs into assets/audio/.
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int _sampleRate = 44100;

void main() {
  _write('tap', _tap());
  _write('explode', _explode());
  _write('collide', _collide());
  _write('win', _win());
  stdout.writeln('Generated 4 sound effects in assets/audio/');
}

void _write(String name, List<double> samples) {
  final file = File('assets/audio/$name.wav');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(_encodeWav(samples));
}

/// Short bright blip for launching a bomb.
List<double> _tap() {
  final n = (_sampleRate * 0.09).round();
  return List<double>.generate(n, (i) {
    final t = i / _sampleRate;
    final env = exp(-t * 32);
    final freq = 880 - 300 * t * 10;
    return sin(2 * pi * freq * t) * env * 0.5;
  });
}

/// Noise burst + low rumble for an explosion.
List<double> _explode() {
  final n = (_sampleRate * 0.55).round();
  final rng = Random(1);
  return List<double>.generate(n, (i) {
    final t = i / _sampleRate;
    final env = exp(-t * 6);
    final noise = (rng.nextDouble() * 2 - 1);
    final rumble = sin(2 * pi * (70 - 30 * t) * t);
    return (noise * 0.6 + rumble * 0.4) * env * 0.85;
  });
}

/// Dull low thud for a blocked collision.
List<double> _collide() {
  final n = (_sampleRate * 0.22).round();
  return List<double>.generate(n, (i) {
    final t = i / _sampleRate;
    final env = exp(-t * 18);
    final tone = sin(2 * pi * 150 * t) + 0.5 * sin(2 * pi * 90 * t);
    return tone * env * 0.45;
  });
}

/// Rising arpeggio for clearing a stage.
List<double> _win() {
  final notes = [523.25, 659.25, 783.99, 1046.5]; // C5 E5 G5 C6
  final noteDur = 0.13;
  final n = (_sampleRate * noteDur * notes.length).round();
  return List<double>.generate(n, (i) {
    final t = i / _sampleRate;
    final noteIndex = (t / noteDur).floor().clamp(0, notes.length - 1);
    final localT = t - noteIndex * noteDur;
    final env = exp(-localT * 6) * (1 - exp(-localT * 200));
    return sin(2 * pi * notes[noteIndex] * t) * env * 0.5;
  });
}

Uint8List _encodeWav(List<double> samples) {
  final dataLength = samples.length * 2;
  final buffer = ByteData(44 + dataLength);

  void writeString(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      buffer.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeString(0, 'RIFF');
  buffer.setUint32(4, 36 + dataLength, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little);
  buffer.setUint16(20, 1, Endian.little); // PCM
  buffer.setUint16(22, 1, Endian.little); // mono
  buffer.setUint32(24, _sampleRate, Endian.little);
  buffer.setUint32(28, _sampleRate * 2, Endian.little); // byte rate
  buffer.setUint16(32, 2, Endian.little); // block align
  buffer.setUint16(34, 16, Endian.little); // bits per sample
  writeString(36, 'data');
  buffer.setUint32(40, dataLength, Endian.little);

  var offset = 44;
  for (final sample in samples) {
    final clamped = sample.clamp(-1.0, 1.0);
    buffer.setInt16(offset, (clamped * 32767).round(), Endian.little);
    offset += 2;
  }
  return buffer.buffer.asUint8List();
}
