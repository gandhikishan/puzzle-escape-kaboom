import 'package:flutter/material.dart';

/// Central color palette so the Flame game and Flutter UI stay visually
/// consistent. Kept separate from [ThemeData] because Flame draws with raw
/// [Color]s on a canvas.
class AppPalette {
  AppPalette._();

  static const Color background = Color(0xFF0E1430);
  static const Color backgroundDeep = Color(0xFF070A1C);
  static const Color surface = Color(0xFF1B2350);
  static const Color boardCell = Color(0xFF222C5E);
  static const Color boardCellAlt = Color(0xFF273266);

  static const Color accent = Color(0xFFFF7A18);
  static const Color accentSecondary = Color(0xFFFFC837);
  static const Color danger = Color(0xFFFF3B6B);
  static const Color success = Color(0xFF36E0A0);

  static const Color bombBody = Color(0xFF11162E);
  static const Color bombHighlight = Color(0xFF3A4486);
  static const Color textPrimary = Color(0xFFF5F7FF);
  static const Color textMuted = Color(0xFF9AA3CF);

  static const List<Color> explosion = [
    Color(0xFFFFF1A8),
    Color(0xFFFFC837),
    Color(0xFFFF7A18),
    Color(0xFFFF3B6B),
  ];
}
