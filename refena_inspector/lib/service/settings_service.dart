import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

class SettingsState {
  final ThemeMode themeMode;

  SettingsState({
    required this.themeMode,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

final settingsProvider = ReduxProvider<SettingsService, SettingsState>((ref) {
  return SettingsService();
});

class SettingsService extends ReduxNotifier<SettingsState> {
  @override
  SettingsState init() {
    return SettingsState(
      themeMode: ThemeMode.system,
    );
  }
}

class SettingsThemeModeAction
    extends ReduxAction<SettingsService, SettingsState> {
  final ThemeMode themeMode;

  SettingsThemeModeAction({
    required this.themeMode,
  });

  @override
  SettingsState reduce() {
    return state.copyWith(
      themeMode: themeMode,
    );
  }
}
