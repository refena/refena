import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector_client/refena_inspector_client.dart';

class RootVm {}

class Child1Vm {}

class Child2Vm {}

class Child3Vm {}

final rootVmProvider = Provider((ref) => RootVm());

final child1VmProvider = ViewProvider((ref) {
  ref.watch(rootVmProvider);
  return Child1Vm();
});

final child2VmProvider = ViewProvider((ref) {
  ref.watch(rootVmProvider);
  return Child2Vm();
});

final child3VmProvider = ViewProvider((ref) {
  ref.watch(child1VmProvider);
  ref.watch(child2VmProvider);
  return Child3Vm();
});

void main() {
  runApp(
    RefenaScope(
      observers: [
        if (kDebugMode) ...[
          RefenaTracingObserver(),
          RefenaInspectorObserver(),
          RefenaDebugObserver(),
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SecondPage()));
            },
            child: const Text('Open second page'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const RefenaTracingPage()));
            },
            child: const Text('Open Tracing'),
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
    ref.dispose(rootVmProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(rootVmProvider);
    ref.watch(child1VmProvider);
    ref.watch(child2VmProvider);
    ref.watch(child3VmProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second page'),
      ),
      body: Container(),
    );
  }
}
