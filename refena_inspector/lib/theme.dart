import 'package:flutter/material.dart';

ThemeData getTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: brightness == Brightness.light ? colorScheme.primary : Colors.deepPurple.shade800,
      selectedLabelTextStyle: const TextStyle(color: Colors.white),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white),
      selectedIconTheme: brightness == Brightness.light ? const IconThemeData(color: Colors.deepPurple) : const IconThemeData(color: Colors.white),
      indicatorColor: brightness == Brightness.light ? null : Colors.deepPurple,
      unselectedIconTheme: const IconThemeData(color: Colors.white),
    ),
  );
}
