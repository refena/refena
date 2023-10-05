import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector_client/refena_inspector_client.dart';

void main() {
  runApp(
    RefenaScope(
      observers: [
        RefenaDebugObserver(),
        RefenaTracingObserver(),
        RefenaInspectorObserver(),
      ],
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
    final vm = context.ref.watch(viewProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refena Tracing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RefenaTracingPage(
                    errorParser: (error) {
                      // if (error is DioException) {
                      //   return {
                      //     'url': error.requestOptions.path,
                      //   };
                      // }
                      return null;
                    },
                  ),
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
          Text('Sum: ${vm.sum}'),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
              children: [
                FilledButton(
                  onPressed: () {
                    context.ref.redux(counterProvider).dispatch(AddAction());
                  },
                  child: Text('Single Action'),
                ),
                FilledButton(
                  onPressed: () {
                    context.ref
                        .redux(counterProvider)
                        .dispatch(NestedAddAction());
                  },
                  child: Text('Nested Action'),
                ),
                FilledButton(
                  onPressed: () {
                    context.ref
                        .redux(notListenedProvider)
                        .dispatch(NotListenedAction());
                  },
                  child: Text('Action without rebuild'),
                ),
                FilledButton(
                  onPressed: () {
                    context.ref.notifier(randomProvider).increment();
                  },
                  child: Text('Notifier Change'),
                ),
                FilledButton(
                  onPressed: () {
                    context.ref.message('LOL!');
                  },
                  child: Text('Custom Message'),
                ),
                FilledButton(
                  onPressed: () {
                    context.ref
                        .redux(counterProvider)
                        .dispatch(MessageAction());
                  },
                  child: Text('Message within Action'),
                ),
                FilledButton(
                  onPressed: () async {
                    await context.ref
                        .redux(counterProvider)
                        .dispatchAsync(FailedDioAction());
                  },
                  child: Text('Action with failed DIO request'),
                ),
                FilledButton(
                  onPressed: () {
                    context.ref.dispose(counterProvider);
                  },
                  child: Text('Dispose'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          context.ref.watch(futureProvider).when(
                data: (value) => Text('Future: $value'),
                loading: () => const CircularProgressIndicator(),
                error: (error, stackTrace) => Text('Error: $error'),
              ),
        ],
      ),
    );
  }
}

class MyObserver extends RefenaObserver {
  @override
  void handleEvent(RefenaEvent event) {
    if (event is ActionDispatchedEvent && event.action is AnotherAction) {
      // ref.notifier(randomProvider).increment();
    }
  }
}

final futureProvider = FutureProvider((ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return 42;
}, debugLabel: 'My Future Provider :)');

class CounterState {
  final int counter;

  const CounterState(this.counter);

  @override
  String toString() => 'CounterState(counter: $counter)';
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

  @override
  void after() {
    dispatch(AnotherAction());
  }
}

class AnotherAction extends ReduxAction<CounterService, CounterState> {
  @override
  CounterState reduce() => throw 'Test Error';
}

class MessageAction extends ReduxAction<CounterService, CounterState> {
  @override
  CounterState reduce() {
    emitMessage('Some Message');
    emitMessage('Another Message');
    return state;
  }
}

class FailedDioAction extends AsyncReduxAction<CounterService, CounterState> {
  @override
  Future<CounterState> reduce() async {
    await Future.delayed(const Duration(seconds: 1));
    // throw 'Test Error';
    await Dio().get('https://restful-booker.herokuapp.com/abc');
    return state;
  }
}

class RandomState {
  final int number;

  const RandomState(this.number);

  @override
  String toString() => 'RandomState(number: $number)';
}

final randomProvider =
    NotifierProvider<RandomService, RandomState>((ref) => RandomService());

class RandomService extends Notifier<RandomState> {
  final Random random = Random();

  @override
  RandomState init() => RandomState(random.nextInt(5));

  void increment() {
    state = RandomState(random.nextInt(5));
  }
}

final notListenedProvider = ReduxProvider((ref) => NotListenedService());

class NotListenedService extends ReduxNotifier<int> {
  @override
  int init() => 0;
}

class NotListenedAction extends ReduxAction<NotListenedService, int> {
  @override
  int reduce() => state + 1;
}

class CounterVm {
  final int sum;

  const CounterVm(this.sum);

  @override
  String toString() => 'CounterVm(sum: $sum)';
}

final viewProvider = ViewProvider((ref) {
  final counterState = ref.watch(counterProvider);
  final randomState = ref.watch(randomProvider);
  return CounterVm(counterState.counter + randomState.number);
});
