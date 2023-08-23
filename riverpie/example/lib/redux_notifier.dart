import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:riverpie_flutter/riverpie_flutter.dart';

sealed class CountEvent {}
final class AddEvent extends CountEvent {
  final int addedAmount;
  AddEvent(this.addedAmount);
}
final class SubtractEvent extends CountEvent {
  final int subtractedAmount;
  SubtractEvent(this.subtractedAmount);
}

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
  runApp(RiverpieScope(
    observer: RiverpieDebugObserver(),
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
