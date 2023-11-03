import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector_client/refena_inspector_client.dart';

void main() {
  runApp(RefenaScope(
    observers: [
      RefenaDebugObserver(),
      RefenaTracingObserver(limit: 200),
      RefenaInspectorObserver(),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyPage(),
    );
  }
}

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = context.ref.watch(_counterProvider);
    return Scaffold(
      body: Column(
        children: [
          Text('Counter: ${counter}'),
          ElevatedButton(
            onPressed: () {
              context.ref.redux(_counterProvider).dispatch(CustomWatchAction());
            },
            child: const Text('Start'),
          ),
          ElevatedButton(
            onPressed: () {
              context.ref.dispose(_counterProvider);
            },
            child: const Text('Dispose'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RefenaTracingPage()),
              );
            },
            child: Text('Show Tracing'),
          ),
        ],
      ),
    );
  }
}

final _counterProvider = ReduxProvider<Counter, int>((ref) => Counter());

class Counter extends ReduxNotifier<int> {
  @override
  int init() => 0;
}

class CustomWatchAction extends WatchAction<Counter, int> {
  late StreamProvider<int> _tempProvider;

  @override
  void before() {
    _tempProvider = StreamProvider<int>((ref) async* {
      for (int i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        yield i;
      }
    });
  }

  @override
  int reduce() {
    return ref.watch(_tempProvider).data ?? 0;
  }

  @override
  void dispose() {
    // called when the notifier is disposed
    ref.dispose(_tempProvider);

    super.dispose();
  }
}
