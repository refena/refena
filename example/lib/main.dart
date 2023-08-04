import 'package:flutter/material.dart';
import 'package:riverpie/riverpie.dart';

final numberProvider = Provider<int>(() => throw 'Not initialized');

final counterProviderA = NotifierProvider<Counter, int>(() => Counter());

final counterProviderB = NotifierProvider<Counter, int>(() => Counter());

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
    final myCounter = ref.watch(counterProviderA);
    return Scaffold(
      body: Column(
        children: [
          Text('The number is $myNumber'),
          Text('The counter is $myCounter'),
          ElevatedButton(
            onPressed: () {
              ref.notify(counterProviderA).increment();
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('Second page'),
        ),
        body: Row(
          children: [
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final myCounter = ref.listen(counterProviderA, (prev, next) {
                    print('(A) Number changed $prev to $next');
                  });
                  print('Rebuild A');
                  return Column(
                    children: [
                      Text('Counter A $myCounter'),
                      ElevatedButton(
                        onPressed: () {
                          ref.notify(counterProviderA).increment();
                        },
                        child: const Text('+ 1'),
                      ),
                    ],
                  );
                }
              ),
            ),
            Expanded(
              child: Consumer(
                  builder: (context, ref, child) {
                    final anotherCounter = ref.listen(counterProviderB, (prev, next) {
                      print('(B) Another number changed $prev to $next');
                    });
                    print('Rebuild B');
                    return Column(
                      children: [
                        Text('Counter B $anotherCounter'),
                        ElevatedButton(
                          onPressed: () {
                            // Calling twice should be ok, rebuilds only once
                            ref.notify(counterProviderB).increment();
                            ref.notify(counterProviderB).increment();
                          },
                          child: const Text('+ 1'),
                        ),
                      ],
                    );
                  }
              ),
            ),
          ],
        ),
      );
    });
  }
}
