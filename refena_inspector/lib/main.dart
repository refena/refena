import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector/pages/home_page.dart';
import 'package:refena_inspector/service/settings_service.dart';
import 'package:refena_inspector/theme.dart';
import 'package:refena_inspector/util/logger.dart';

final _refenaLogger = Logger('Refena');

void main() {
  initLogger();
  runApp(
    RefenaScope(
      observers: [
        if (kDebugMode) ...[
          RefenaDebugObserver(
            onLine: (line) => _refenaLogger.info(line),
          ),
          RefenaTracingObserver(),
        ],
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.ref
        .watch(settingsProvider.select((settings) => settings.themeMode));
    return MaterialApp(
      title: 'Refena Inspector',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: getTheme(Brightness.light),
      darkTheme: getTheme(Brightness.dark),
      home: const HomePage(),
    );
  }
}
