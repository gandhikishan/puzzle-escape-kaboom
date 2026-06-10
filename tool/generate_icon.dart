/// Generates the app icon, adaptive foreground, and in-app logo for
/// "Puzzle Escape - Kaboom".
///
/// Run from the project root:
///   dart run tool/generate_icon.dart
///   dart run flutter_launcher_icons
///
/// Drawing the artwork in code keeps the repo free of binary design files and
/// lets the brand be tweaked without an external editor.
library;

import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';

const int _size = 1024;

void main() {
  // Full-bleed launcher icon (square, masked by the launcher).
  final icon = Image(width: _size, height: _size, numChannels: 4);
  _paintRadialBackground(icon);
  _drawBomb(icon, cx: 512, cy: 560, radius: 300);
  _save(icon, 'assets/icon/icon.png');

  // Adaptive foreground: transparent, content kept inside the safe zone.
  final fg = Image(width: _size, height: _size, numChannels: 4);
  _drawBomb(fg, cx: 512, cy: 540, radius: 230);
  _save(fg, 'assets/icon/icon_foreground.png');

  // In-app logo mark: transparent background, bomb only.
  final logo = Image(width: 512, height: 512, numChannels: 4);
  _drawBomb(logo, cx: 256, cy: 280, radius: 150);
  _save(logo, 'assets/branding/logo.png');

  stdout.writeln('Generated icon.png, icon_foreground.png and logo.png');
}

void _save(Image img, String path) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(encodePng(img));
}

/// Warm explosive radial gradient (bright core -> deep red edges).
void _paintRadialBackground(Image img) {
  final cx = img.width / 2;
  final cy = img.height / 2;
  final maxR = sqrt(cx * cx + cy * cy);
  const inner = [255, 190, 70];
  const mid = [255, 110, 24];
  const outer = [150, 28, 12];

  for (var y = 0; y < img.height; y++) {
    for (var x = 0; x < img.width; x++) {
      final d = (sqrt(pow(x - cx, 2) + pow(y - cy, 2)) / maxR).clamp(0.0, 1.0);
      List<int> c;
      if (d < 0.5) {
        c = _lerp(inner, mid, d / 0.5);
      } else {
        c = _lerp(mid, outer, (d - 0.5) / 0.5);
      }
      img.setPixelRgba(x, y, c[0], c[1], c[2], 255);
    }
  }
}

List<int> _lerp(List<int> a, List<int> b, double t) => [
      (a[0] + (b[0] - a[0]) * t).round(),
      (a[1] + (b[1] - a[1]) * t).round(),
      (a[2] + (b[2] - a[2]) * t).round(),
    ];

void _drawBomb(Image img, {required int cx, required int cy, required int radius}) {
  // Drop shadow.
  fillCircle(img,
      x: cx,
      y: cy + (radius * 0.10).round(),
      radius: radius,
      color: ColorRgba8(0, 0, 0, 90));

  // Body.
  fillCircle(img,
      x: cx, y: cy, radius: radius, color: ColorRgba8(17, 22, 46, 255));

  // Rim light.
  drawCircle(img,
      x: cx,
      y: cy,
      radius: radius,
      color: ColorRgba8(70, 90, 150, 180));

  // Glossy highlight (top-left).
  fillCircle(img,
      x: (cx - radius * 0.34).round(),
      y: (cy - radius * 0.36).round(),
      radius: (radius * 0.26).round(),
      color: ColorRgba8(120, 140, 210, 150));

  // Fuse cap on top.
  final capY = (cy - radius * 0.92).round();
  fillCircle(img,
      x: cx, y: capY, radius: (radius * 0.18).round(),
      color: ColorRgba8(60, 70, 110, 255));

  // Spark glow above the cap.
  final sparkY = (capY - radius * 0.34).round();
  fillCircle(img,
      x: cx,
      y: sparkY,
      radius: (radius * 0.30).round(),
      color: ColorRgba8(255, 120, 30, 130));
  fillCircle(img,
      x: cx, y: sparkY, radius: (radius * 0.17).round(),
      color: ColorRgba8(255, 200, 60, 230));
  fillCircle(img,
      x: cx, y: sparkY, radius: (radius * 0.08).round(),
      color: ColorRgba8(255, 255, 220, 255));

  // Spark rays.
  final rng = Random(7);
  for (var i = 0; i < 8; i++) {
    final a = (i / 8) * pi * 2 + rng.nextDouble() * 0.2;
    final r1 = radius * 0.30;
    final r2 = radius * (0.45 + rng.nextDouble() * 0.18);
    drawLine(img,
        x1: (cx + cos(a) * r1).round(),
        y1: (sparkY + sin(a) * r1).round(),
        x2: (cx + cos(a) * r2).round(),
        y2: (sparkY + sin(a) * r2).round(),
        color: ColorRgba8(255, 210, 80, 220),
        thickness: max(2, (radius * 0.03).round()));
  }
}
