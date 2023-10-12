import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector/service/settings_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final settingsState = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              _SettingsEntry(
                label: 'Theme',
                child: DropdownButton<ThemeMode>(
                  value: settingsState.themeMode,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    ref
                        .redux(settingsProvider)
                        .dispatch(SettingsThemeModeAction(themeMode: value));
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                ),
              ),
              if (kDebugMode)
                _SettingsEntry(
                  label: 'Tracing',
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const RefenaTracingPage()));
                    },
                    child: const Text('Open'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingsEntry({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: child,
    );
  }
}
