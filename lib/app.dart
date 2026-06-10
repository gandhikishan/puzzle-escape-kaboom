import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/home_screen.dart';

/// Root widget. Routing is done with imperative [Navigator] pushes from the
/// screens, so the app only needs to declare its home here.
class BombsAndPuzzlesApp extends StatelessWidget {
  const BombsAndPuzzlesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Puzzle Escape - Kaboom',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
