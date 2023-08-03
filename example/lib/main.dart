import 'package:flutter/material.dart';
import 'package:riverpie/riverpie.dart';

final numberProvider = Provider<int>(() => throw 'Not initialized');

final counterProvider = NotifierProvider<Counter, int>(() => Counter());

class Counter extends Notifier<int> {
  @override
  int init() => 10;

  void increment() => state++;
}

void main() {
  runApp(
    RiverpieScope(
      overrides: [
        numberProvider.overrideWithValue(999),
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

class _HomePageState extends State<HomePage> with Riverpie {
  @override
  Widget build(BuildContext context) {
    final myNumber = ref.watch(numberProvider);
    final myCounter = ref.watch(counterProvider);
    return Scaffold(
      body: Column(
        children: [
          Text('The number is $myNumber'),
          Text('The counter is $myCounter'),
          ElevatedButton(
            onPressed: () {
              ref.notify(counterProvider).increment();
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
    return Consumer(builder: (context, ref, child) {
      final myNumber = ref.watch(numberProvider);
      final myCounter = ref.watch(counterProvider);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Second page'),
        ),
        body: Column(
          children: [
            Text('The number is $myNumber'),
            Text('The counter is $myCounter'),
            ElevatedButton(
              onPressed: () {
                ref.notify(counterProvider).increment();
              },
              child: const Text('+ 1'),
            ),
          ],
        ),
      );
    });
  }
}
