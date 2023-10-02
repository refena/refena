import 'package:flutter/material.dart';

ThemeData getTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.primary,
      selectedLabelTextStyle: const TextStyle(color: Colors.white),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white),
      selectedIconTheme: const IconThemeData(color: Colors.deepPurple),
      unselectedIconTheme: const IconThemeData(color: Colors.white),
    ),
  );
}
