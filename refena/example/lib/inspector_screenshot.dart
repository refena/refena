import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector_client/refena_inspector_client.dart';

final persistenceProvider = Provider<int>((ref) {
  return 3;
}, debugLabel: 'Persistence');

final counterProviderA = NotifierProvider<Counter, int>((ref) {
  ref.read(persistenceProvider);
  return Counter(debugLabel: 'Counter A');
});

final counterProviderB = NotifierProvider<Counter, int>((ref) {
  ref.read(persistenceProvider);
  return Counter(debugLabel: 'Counter B');
});

class Vm {
  final int a;
  final int b;
  void Function() incrementA;
  void Function() incrementB;

  Vm({
    required this.a,
    required this.b,
    required this.incrementA,
    required this.incrementB,
  });

  @override
  String toString() => 'Vm(a: $a, b: $b)';
}

final viewProvider = ViewProvider((ref) {
  final a =
      ref.watch(counterProviderA, rebuildWhen: (prev, next) => next % 2 == 0);
  final b = ref.watch(counterProviderB);

  return Vm(
    a: a,
    b: b,
    incrementA: () => ref.notifier(counterProviderA).increment(),
    incrementB: () {
      ref.notifier(counterProviderA).increment();
      ref.notifier(counterProviderB).increment();
    },
  );
}, debugLabel: 'CounterVm');

class Counter extends Notifier<int> {
  Counter({super.debugLabel});

  @override
  int init() => 10;

  void increment() => state++;
}

void main() {
  runApp(
    RefenaScope(
      observers: [
        if (kDebugMode) ...[
          RefenaInspectorObserver(),
          RefenaDebugObserver(),
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
    return const MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with Refena {
  @override
  Widget build(BuildContext context) {
    final myCounter = ref.watch(counterProviderA);
    return Scaffold(
      body: Column(
        children: [
          Text('The counter is $myCounter'),
          ElevatedButton(
            onPressed: () {
              ref.notifier(counterProviderA).increment();
            },
            child: const Text('+ 1'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SecondPage()));
            },
            child: const Text('Open second page'),
          ),
        ],
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second page'),
      ),
      body: Consumer(
          debugParent: this,
          builder: (context, ref) {
            final vm = ref.watch(viewProvider);
            return Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Counter A ${vm.a}'),
                        ElevatedButton(
                          onPressed: () => vm.incrementA(),
                          child: const Text('+ 1'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Counter B ${vm.b}'),
                        ElevatedButton(
                          onPressed: () => vm.incrementB(),
                          child: const Text('+ 1'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }
}
