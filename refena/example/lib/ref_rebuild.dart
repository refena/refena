import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector_client/refena_inspector_client.dart';

void main() {
  runApp(RefenaScope(
    observers: [
      if (kDebugMode) ...[
        RefenaInspectorObserver(),
        RefenaTracingObserver(),
      ],
    ],
    child: MyApp(),
  ));
}

final _parentProvider = ViewProvider((ref) {
  return Random().nextInt(100);
});

final _viewProvider = ViewProvider((ref) {
  return ref.watch(_parentProvider) + Random().nextInt(100);
});

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final number = context.watch(_viewProvider);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Number: $number'),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () => context.rebuild(_viewProvider),
                  child: Text('Rebuild'),
                ),
                FilledButton(
                  onPressed: () => context.global.dispatch(RebuildAction()),
                  child: Text('RebuildAction'),
                ),
                FilledButton(
                  onPressed: () => context.rebuild(_parentProvider),
                  child: Text('Rebuild Parent'),
                ),
                FilledButton(
                  onPressed: () => context.global.dispatch(RebuildParentAction()),
                  child: Text('RebuildParentAction'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RebuildAction extends GlobalAction {
  @override
  void reduce() {
    ref.rebuild(_viewProvider);
  }
}

class RebuildParentAction extends GlobalAction {
  @override
  void reduce() {
    ref.rebuild(_parentProvider);
  }
}

