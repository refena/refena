import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpie_flutter/riverpie_flutter.dart';

void main() {
  final observer = RiverpieHistoryObserver(HistoryObserverConfig(
    saveChangeEvents: false,
    saveEventEmittedEvents: true,
  ));

  setUp(() {
    observer.clear();
  });

  testWidgets('Should use debugLabel of widget', (tester) async {
    final ref = RiverpieScope(
      observer: observer,
      child: MaterialApp(
        home: MyPage(),
      ),
    );
    await tester.pumpWidget(ref);

    expect(find.text('0'), findsOneWidget);
    expect(find.text('Increment'), findsOneWidget);

    await tester.tap(find.text('Increment'));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);

    final notifier = ref.anyNotifier(counterProvider);
    expect(observer.history, [
      EventEmittedEvent(
        debugOrigin: 'MyPage',
        notifier: notifier,
        event: CounterEvent.increment,
      ),
    ]);
  });

  testWidgets('Should use label of Consumer', (tester) async {
    final ref = RiverpieScope(
      observer: observer,
      child: MaterialApp(
        home: ConsumerPage(),
      ),
    );
    await tester.pumpWidget(ref);

    expect(find.text('0'), findsOneWidget);
    expect(find.text('Increment'), findsOneWidget);

    await tester.tap(find.text('Increment'));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);

    final notifier = ref.redux(counterProvider).notifier;
    expect(observer.history, [
      EventEmittedEvent(
        debugOrigin: 'Banana',
        notifier: notifier,
        event: CounterEvent.increment,
      ),
    ]);
  });
}

enum CounterEvent { increment }

final counterProvider = ReduxProvider<Counter, int, CounterEvent>((ref) {
  return Counter();
});

class Counter extends ReduxNotifier<int, CounterEvent> {
  @override
  int init() => 0;

  @override
  int reduce(CounterEvent event) {
    return switch (event) {
      CounterEvent.increment => state + 1,
    };
  }
}

class MyPage extends StatelessWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(context.ref.watch(counterProvider).toString()),
          ElevatedButton(
            onPressed: () {
              context.ref.redux(counterProvider).emit(CounterEvent.increment);
            },
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}

class ConsumerPage extends StatelessWidget {
  const ConsumerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      debugLabel: 'Banana',
      builder: (context, ref) {
        return Column(
          children: [
            Text(ref.watch(counterProvider).toString()),
            ElevatedButton(
              onPressed: () {
                ref.redux(counterProvider).emit(CounterEvent.increment);
              },
              child: const Text('Increment'),
            ),
          ],
        );
      },
    );
  }
}
