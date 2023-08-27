import 'package:flutter/material.dart';
import 'package:riverpie_flutter/riverpie_flutter.dart';

void main() {
  runApp(
    RiverpieScope(
      observer: RiverpieTracingObserver(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MyPage(),
    );
  }
}

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final counterState = context.ref.watch(counterProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpie Tracing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RiverpieTracingPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Counter: ${counterState.counter}'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () {
                  context.ref.redux(counterProvider).dispatch(AddAction());
                },
                child: Text('Single Action'),
              ),
              const SizedBox(width: 20),
              FilledButton(
                onPressed: () {
                  context.ref.redux(counterProvider).dispatch(NestedAddAction());
                },
                child: Text('Nested Action'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CounterState {
  final int counter;

  const CounterState(this.counter);
}

final counterProvider =
    ReduxProvider<CounterService, CounterState>((ref) => CounterService());

class CounterService extends ReduxNotifier<CounterState> {
  @override
  CounterState init() => CounterState(0);
}

class AddAction extends ReduxAction<CounterService, CounterState> {
  @override
  CounterState reduce() => CounterState(state.counter + 1);
}

class NestedAddAction extends ReduxAction<CounterService, CounterState> {
  @override
  CounterState reduce() {
    final result = dispatch(AddAction());
    return CounterState(result.counter + 1);
  }
}
