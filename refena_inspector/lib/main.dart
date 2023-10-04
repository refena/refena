import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector/pages/home_page.dart';
import 'package:refena_inspector/theme.dart';
import 'package:refena_inspector/util/logger.dart';

final _refenaLogger = Logger('Refena');

void main() {
  initLogger();
  runApp(
    RefenaScope(
      observers: [
        RefenaDebugObserver(
          onLine: (line) => _refenaLogger.info(line),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Refena Inspector',
      debugShowCheckedModeBanner: false,
      theme: getTheme(),
      home: const HomePage(),
    );
  }
}
