import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/addons.dart';
import 'package:refena_flutter/refena_flutter.dart';

const _expectedText = 'Second Page';
const _pushText = 'Push page';

void main() {
  testWidgets('Should navigate with ref.read', (tester) async {
    await _testNavigation(tester, _RefReadPage());
  });

  testWidgets('Should navigate with ReduxAction', (tester) async {
    await _testNavigation(tester, _ReduxPage());
  });

  testWidgets('Should navigate with custom ReduxAction', (tester) async {
    final observer = RefenaHistoryObserver.only(
      actionDispatched: true,
    );
    final ref = RefenaScope(
      observer: observer,
      child: _App(_CustomReduxPage()),
    );

    await tester.pumpWidget(ref);

    // Verify that second page is not visible.
    expect(find.text(_expectedText), findsNothing);

    await tester.tap(find.text(_pushText));

    await tester.pumpAndSettle();

    expect(find.text(_expectedText), findsOneWidget);

    // Check events
    final navigationNotifier = ref.notifier(globalReduxProvider);
    final notifier = ref.notifier(_myReduxProvider);
    expect(observer.history.length, 2);
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: '_CustomReduxPage',
        debugOriginRef: WidgetRebuildable<_CustomReduxPage>(),
        notifier: notifier,
        action: _MyReduxAction(),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_MyReduxAction',
        debugOriginRef: _MyReduxAction(),
        notifier: navigationNotifier,
        action: NavigateAction.push(_SecondPage()),
      ),
    ]);
  });

  testWidgets('Should navigate with extended ReduxAction', (tester) async {
    final observer = RefenaHistoryObserver.only(
      actionDispatched: true,
    );
    final ref = RefenaScope(
      observer: observer,
      child: _App(_ExtendedReduxPage()),
    );

    await tester.pumpWidget(ref);

    // Verify that second page is not visible.
    expect(find.text(_expectedText), findsNothing);

    await tester.tap(find.text(_pushText));

    await tester.pumpAndSettle();

    expect(find.text(_expectedText), findsOneWidget);

    // Check events
    final navigationNotifier = ref.notifier(globalReduxProvider);
    expect(observer.history.length, 1);
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: '_ExtendedReduxPage',
        debugOriginRef: WidgetRebuildable<_ExtendedReduxPage>(),
        notifier: navigationNotifier,
        action: _ExtendedNavigationAction(),
      ),
    ]);
  });
}

Future<void> _testNavigation(
  WidgetTester tester,
  Widget home,
) async {
  final ref = RefenaScope(
    child: _App(home),
  );

  await tester.pumpWidget(ref);

  // Verify that second page is not visible.
  expect(find.text(_expectedText), findsNothing);

  await tester.tap(find.text(_pushText));

  await tester.pumpAndSettle();

  expect(find.text(_expectedText), findsOneWidget);
}

class _App extends StatelessWidget {
  final Widget home;

  _App(this.home);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: context.ref.watch(navigationProvider).key,
      home: home,
    );
  }
}

class _RefReadPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text(_pushText),
          onPressed: () {
            context.ref.read(navigationProvider).push(_SecondPage());
          },
        ),
      ),
    );
  }
}

class _ReduxPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text(_pushText),
          onPressed: () {
            context.ref.dispatchAsync(NavigateAction.push(_SecondPage()));
          },
        ),
      ),
    );
  }
}

class _CustomReduxPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text(_pushText),
          onPressed: () {
            context.ref.redux(_myReduxProvider).dispatch(_MyReduxAction());
          },
        ),
      ),
    );
  }
}

class _ExtendedReduxPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text(_pushText),
          onPressed: () {
            context.ref.dispatchAsync(_ExtendedNavigationAction());
          },
        ),
      ),
    );
  }
}

class _SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(_expectedText),
      ),
    );
  }
}

final _myReduxProvider = ReduxProvider((ref) => _MyReduxService());

class _MyReduxService extends ReduxNotifier<int> {
  @override
  int init() => 0;
}

class _MyReduxAction extends ReduxAction<_MyReduxService, int>
    with GlobalActions {
  @override
  int reduce() {
    global.dispatchAsync(NavigateAction.push(_SecondPage()));
    return state;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _MyReduxAction;

  @override
  int get hashCode => 0;
}

class _ExtendedNavigationAction<T> extends BaseNavigationPushAction<T> {
  @override
  Future<T?> navigate() async {
    GlobalKey<NavigatorState> key = ref.read(navigationProvider).key;
    T? result = await key.currentState!.push<T>(
      MaterialPageRoute(
        builder: (_) => _SecondPage(),
      ),
    );

    return result;
  }

  @override
  bool operator ==(Object other) => other is _ExtendedNavigationAction;

  @override
  int get hashCode => 0;
}
