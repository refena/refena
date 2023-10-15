import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

final myFutureNotifier = FutureProvider((ref) async {
  await Future.delayed(const Duration(seconds: 2));
  return 10;
});

final myNotifier =
    AsyncNotifierProvider<DelayedCounter, int>((ref) => DelayedCounter());

class DelayedCounter extends AsyncNotifier<int> {
  @override
  Future<int> init() async {
    await Future.delayed(const Duration(seconds: 3));
    return 10;
  }

  void increment() async {
    await setState((snapshot) async {
      await Future.delayed(const Duration(seconds: 2));
      final curr = await snapshot.currFuture;
      return curr + 1;
    });
  }
}

void main() {
  runApp(
    RefenaScope(
      observers: [
        if (kDebugMode) RefenaDebugObserver(),
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with Refena {
  @override
  Widget build(BuildContext context) {
    final myCounter = ref.watch(myNotifier);
    return Scaffold(
      body: Column(
        children: [
          myCounter.when(
            data: (data) => Text('The counter is ${myCounter.data}'),
            loading: () => CircularProgressIndicator(),
            error: (e, st) => Column(
              children: [
                Text(e.toString()),
                Text(st.toString()),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.notifier(myNotifier).increment();
            },
            child: const Text('+ 1'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const MySecondPage()));
            },
            child: const Text('Open second page'),
          ),
        ],
      ),
    );
  }
}

class MySecondPage extends StatelessWidget {
  const MySecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.ref.watch(myNotifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second page'),
      ),
      body: Column(
        children: [
          Text('The counter is ${state.data}'),
          ElevatedButton(
            onPressed: () {
              context.ref.notifier(myNotifier).increment();
            },
            child: const Text('+ 1'),
          ),
          if (state.isLoading)
            const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
