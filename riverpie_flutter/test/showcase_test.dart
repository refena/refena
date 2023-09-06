import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpie_flutter/riverpie_flutter.dart';

/// The test that is shown in the README.md

final counterProvider = NotifierProvider<Counter, int>((ref) {
  return Counter();
});

class Counter extends Notifier<int> {
  @override
  int init() => 0;

  void increment() => state++;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyPage(),
    );
  }
}

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.ref.watch(counterProvider);
    return Scaffold(
      body: Center(
        child: Text('$count'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.ref.notifier(counterProvider).increment();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class MockCounter extends Counter {
  @override
  int init() => 0;

  @override
  void increment() => state += 2;
}

void main() {
  testWidgets('Showcase test', (tester) async {
    final observer = RiverpieHistoryObserver.all();
    final scope = RiverpieScope(
      observer: observer,
      overrides: [
        counterProvider.overrideWithNotifier(
          (ref) => MockCounter(),
        ),
      ],
      child: MyApp(),
    );

    await tester.pumpWidget(scope);

    expect(find.text('0'), findsOneWidget);

    // update via UI
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('2'), findsOneWidget);

    // update the state directly
    scope.notifier(counterProvider).increment();
    await tester.pump();

    expect(find.text('4'), findsOneWidget);

    // check events
    final counterNotifier = scope.notifier(counterProvider);
    expect(observer.history, [
      ProviderInitEvent(
        provider: counterProvider,
        notifier: counterNotifier,
        cause: ProviderInitCause.override,
        value: 0,
      ),
      ChangeEvent(
        notifier: counterNotifier,
        action: null,
        prev: 0,
        next: 2,
        rebuild: [WidgetRebuildable<MyPage>()],
      ),
      ChangeEvent(
        notifier: counterNotifier,
        action: null,
        prev: 2,
        next: 4,
        rebuild: [WidgetRebuildable<MyPage>()],
      ),
    ]);
  });
}
