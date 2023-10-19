import 'package:example/refena.dart';
import 'package:example/riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector_client/refena_inspector_client.dart';
import 'package:refena_riverpod_extension/refena_riverpod_extension.dart';

class Vm {
  final int refenaCounter;
  final int riverpodCounter;

  Vm({
    required this.refenaCounter,
    required this.riverpodCounter,
  });
}

final vmProvider = ViewProvider((ref) {
  return Vm(
    refenaCounter: ref.watch(refenaCounter),
    riverpodCounter: ref.riverpod.watch(riverpodCounter),
  );
});

void main() {
  runApp(
    riverpod.ProviderScope(
      child: RefenaScope(
        observers: kDebugMode
            ? [
                RefenaDebugObserver(),
                RefenaTracingObserver(),
                RefenaInspectorObserver(),
              ]
            : [],
        child: RefenaRiverpodExtensionScope(
          child: const MyApp(),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MyPage(),
    );
  }
}

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SecondPage()));
            },
            child: const Text('Open second page'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ReduxPage()));
            },
            child: const Text('Open redux page'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) {
                  return const RefenaTracingPage();
                }),
              );
            },
            child: const Text('Open tracing'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) {
                  return const RefenaGraphPage(showWidgets: true);
                }),
              );
            },
            child: const Text('Open graph'),
          ),
        ],
      ),
    );
  }
}

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> with Refena {
  @override
  void dispose() {
    ref.dispose(vmProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(vmProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second page'),
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('The Refena counter is: ${vm.refenaCounter}'),
                ElevatedButton(
                  onPressed: () {
                    ref.notifier(refenaCounter).setState((old) => old + 1);
                  },
                  child: const Text('+ 1'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text('The Riverpod counter is: ${vm.riverpodCounter}'),
                riverpod.Consumer(builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () {
                      ref.read(riverpodCounter.notifier).state += 1;
                    },
                    child: const Text('+ 1'),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReduxPage extends riverpod.ConsumerWidget {
  const ReduxPage({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redux page'),
      ),
      body: Column(
        children: [
          Text('State: ${context.ref.watch(refenaReduxCounter)}'),
          ElevatedButton(
            onPressed: () {
              ref.read(riverpodNotifierProvider.notifier).dispatch();
            },
            child: const Text('Increment from Riverpod'),
          ),
          ElevatedButton(
            onPressed: () {
              context.ref.redux(refenaReduxCounter).dispatch(IncrementAction());
            },
            child: const Text('Increment from Refena'),
          ),
        ],
      ),
    );
  }
}
