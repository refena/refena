import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riverpie/riverpie.dart';

final counter = StateProvider((ref) => 0);

void main() {
  runApp(
    RiverpieScope(
      observer: kDebugMode ? const RiverpieDebugObserver() : null,
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
    final ref = context.ref; // store it for better performance
    final count = ref.watch(counter);
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
        ],
      ),
    );
  }
}
