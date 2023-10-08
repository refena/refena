import 'package:flutter/material.dart';

/// Returns a [ThemeData] based on the [brightness].
ThemeData getTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: brightness == Brightness.light
          ? colorScheme.primary
          : Colors.grey.shade900,
      selectedLabelTextStyle: const TextStyle(color: Colors.white),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white),
      selectedIconTheme: brightness == Brightness.light
          ? const IconThemeData(color: Colors.deepPurple)
          : const IconThemeData(color: Colors.white),
      unselectedIconTheme: const IconThemeData(color: Colors.white),
    ),
  );
}
