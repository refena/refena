import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

void main() {
  runApp(
    RefenaScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Open the MyCounterPage'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyCounterPage(),
                ),
              ),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyCounterPage extends StatelessWidget {
  const MyCounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: _notifierProvider,
      init: (context, ref) => ref.notifier(_notifierProvider).increment(),
      builder: (context, vm) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('NotifierContext'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Counter: $vm'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.notifier(_notifierProvider).increment(),
            child: const Icon(Icons.add),
          ),
        );
      }
    );
  }
}

final _notifierProvider = NotifierProvider<_Notifier, int>((ref) => _Notifier());

class _Notifier extends Notifier<int> with ViewBuildContext {
  @override
  int init() => 0;

  void increment() async {
    await Future.delayed(const Duration(seconds: 1));
    state++;
    print('Disposed: $disposed');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Counter: $state'),
      ),
    );
  }
}
