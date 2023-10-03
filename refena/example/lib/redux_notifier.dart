import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

final counterProvider = ReduxProvider<ReduxCounter, int>((ref) {
  return ReduxCounter(ref.notifier(counterProviderA));
});

class ReduxCounter extends ReduxNotifier<int> {
  final Counter counter;
  ReduxCounter(this.counter);

  @override
  int init() => 0;
}

class AddAction extends ReduxAction<ReduxCounter, int> {
  final int addedAmount;

  AddAction(this.addedAmount);

  @override
  int reduce() {
    return state + addedAmount;
  }
}

class SubtractAction extends ReduxAction<ReduxCounter, int> {
  final int subtractedAmount;

  SubtractAction(this.subtractedAmount);

  @override
  int reduce() {
    return state - subtractedAmount;
  }
}

void main() {
  runApp(RefenaScope(
    observers: [
      RefenaDebugObserver(),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyPage(),
    );
  }
}

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final state = ref.watch(counterProvider);
    return Scaffold(
      body: Column(
        children: [
          Text(state.toString()),
          ElevatedButton(
            onPressed: () {
              ref.redux(counterProvider).dispatch(AddAction(2));
            },
            child: const Text('Increment'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.redux(counterProvider).dispatch(SubtractAction(3));
            },
            child: const Text('Decrement'),
          ),
        ],
      ),
    );
  }
}
