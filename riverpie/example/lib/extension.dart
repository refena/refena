import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riverpie_flutter/riverpie_flutter.dart';

final counter = StateProvider((ref) => 0);

void main() {
  runApp(
    RiverpieScope(
      observer: kDebugMode ? RiverpieDebugObserver() : null,
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
      home: MyPage(),
    );
  }
}

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.ref.watch(counter);
    return Scaffold(
      body: Column(
        children: [
          Text('The counter is: $count'),
          ElevatedButton(
            onPressed: () {
              context.ref.notifier(counter).setState((old) => old + 1);
            },
            child: const Text('+ 1'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SecondPage()));
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
      body: Column(
        children: [
          Text('The counter is: ${context.ref.watch(counter)}'),
          ElevatedButton(
            onPressed: () {
              context.ref.notifier(counter).setState((old) => old + 1);
            },
            child: const Text('+ 1'),
          ),
        ],
      ),
    );
  }
}
