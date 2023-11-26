import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector_client/refena_inspector_client.dart';

void main() {
  runApp(
    RefenaScope(
      observers: [
        if (kDebugMode) ...[
          RefenaInspectorObserver(),
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
    return Scaffold(
      body: Column(
        children: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FuturePage(1),
                ),
              );
            },
            child: Text('Button 1'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FuturePage(2),
                ),
              );
            },
            child: Text('Button 2'),
          ),
          FilledButton(
            onPressed: () {
              context.dispose(familyProvider);
            },
            child: Text('Dispose Family'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RefenaTracingPage(),
                ),
              );
            },
            child: const Text('Open Tracing'),
          ),
        ],
      ),
    );
  }
}

class FuturePage extends StatelessWidget {
  final int param;

  const FuturePage(this.param);

  @override
  Widget build(BuildContext context) {
    final value = context.watch(familyProvider(param));
    return Scaffold(
      appBar: AppBar(
        title: Text('FuturePage $param'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            value.maybeWhen(
              skipLoading: false,
              data: (data) => Text(data, style: const TextStyle(fontSize: 30)),
              orElse: () => const CircularProgressIndicator(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  context.notifier(counterProvider).setState((old) => old + 1),
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}

final counterProvider = StateProvider((ref) => 1);

final familyProvider = FutureFamilyProvider<String, int>((ref, param) async {
  await Future.delayed(const Duration(seconds: 1));
  final counter = ref.watch(counterProvider);
  return (param * 2 + counter).toString();
});
