import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../../util/skip_microtasks.dart';

void main() {
  test('Should rebuild when watching provider rebuilds', () async {
    final observer = RefenaHistoryObserver.only(
      actionDispatched: true,
      change: true,
    );

    final ref = RefenaContainer(
      observers: [observer],
    );

    final reduxProvider = ReduxProvider<_ReduxNotifier, _ReduxState>((ref) {
      return _ReduxNotifier();
    });

    expect(ref.read(_counterAProvider), 10);
    expect(ref.read(reduxProvider).counter, 0);
    expect(ref.read(reduxProvider).name, '');

    ref.redux(reduxProvider).dispatch(_WatchAction());
    expect(ref.read(_counterAProvider), 10);
    expect(ref.read(reduxProvider).counter, 10);
    expect(ref.read(reduxProvider).name, '');

    ref.redux(reduxProvider).dispatch(_UpdateNameAction('test'));
    await skipAllMicrotasks();
    expect(ref.read(_counterAProvider), 10);
    expect(ref.read(reduxProvider).counter, 10);
    expect(ref.read(reduxProvider).name, 'test');
    expect(observer.dispatchedActions.length, 2);
    expect(observer.dispatchedActions, [
      isA<_WatchAction>(),
      isA<_UpdateNameAction>(),
    ]);

    ref.notifier(_counterAProvider).setState((_) => 20);
    await skipAllMicrotasks();
    expect(ref.read(_counterAProvider), 20);
    expect(ref.read(reduxProvider).counter, 20);
    expect(ref.read(reduxProvider).name, 'test');
    expect(observer.dispatchedActions.length, 3);
    expect(observer.dispatchedActions, [
      isA<_WatchAction>(),
      isA<_UpdateNameAction>(),
      isA<WatchUpdateAction>(),
    ]);

    ref.redux(reduxProvider).dispatch(_UpdateNameAction('test2'));
    await skipAllMicrotasks();
    expect(ref.read(_counterAProvider), 20);
    expect(ref.read(reduxProvider).counter, 20);
    expect(ref.read(reduxProvider).name, 'test2');

    ref.notifier(_counterAProvider).setState((_) => 30);
    await skipAllMicrotasks();
    expect(ref.read(_counterAProvider), 30);
    expect(ref.read(reduxProvider).counter, 30);
    expect(ref.read(reduxProvider).name, 'test2');
    expect(observer.dispatchedActions.length, 5);
    expect(observer.dispatchedActions, [
      isA<_WatchAction>(),
      isA<_UpdateNameAction>(),
      isA<WatchUpdateAction>(),
      isA<_UpdateNameAction>(),
      isA<WatchUpdateAction>(),
    ]);
    expect(observer.history.length, 12);
    expect(observer.history, [
      isA<ActionDispatchedEvent>(),
      isA<ChangeEvent<_ReduxState>>(),
      isA<ActionDispatchedEvent>(),
      isA<ChangeEvent<_ReduxState>>(),
      isA<ChangeEvent<int>>(),
      isA<ActionDispatchedEvent>(),
      isA<ChangeEvent<_ReduxState>>(),
      isA<ActionDispatchedEvent>(),
      isA<ChangeEvent<_ReduxState>>(),
      isA<ChangeEvent<int>>(),
      isA<ActionDispatchedEvent>(),
      isA<ChangeEvent<_ReduxState>>(),
    ]);

    final watchUpdateEvent = observer.history[5] as ActionDispatchedEvent;
    expect(watchUpdateEvent.action, isA<WatchUpdateAction>());
    expect(watchUpdateEvent.debugOrigin, '_WatchAction');
    expect(watchUpdateEvent.debugOriginRef, ref.anyNotifier(reduxProvider));
  });

  test('Should unwatch old provider', () async {
    final observer = RefenaHistoryObserver.only(
      startImmediately: false,
      actionDispatched: true,
    );
    final ref = RefenaContainer(
      observers: [observer],
    );

    final reduxProvider = ReduxProvider<_ReduxNotifier, _ReduxState>((ref) {
      // This provider depends on the parent provider
      ref.read(_parentProvider);
      return _ReduxNotifier();
    });

    final parentNotifier = ref.anyNotifier(_parentProvider);
    final switchNotifier = ref.anyNotifier(_switchProvider);
    final notifierA = ref.anyNotifier(_counterAProvider);
    final notifierB = ref.anyNotifier(_counterBProvider);
    final reduxNotifier = ref.anyNotifier(reduxProvider);

    expect(ref.read(_switchProvider), true);
    expect(ref.read(_counterAProvider), 10);
    expect(ref.read(_counterBProvider), 20);
    expect(ref.read(reduxProvider).counter, 0);

    // Check initial dependency graph
    expect(parentNotifier.dependencies, isEmpty);
    expect(parentNotifier.dependents, {reduxNotifier});
    expect(switchNotifier.dependencies, isEmpty);
    expect(switchNotifier.dependents, isEmpty);
    expect(notifierA.dependencies, isEmpty);
    expect(notifierA.dependents, isEmpty);
    expect(notifierB.dependencies, isEmpty);
    expect(notifierB.dependents, isEmpty);
    expect(reduxNotifier.dependencies, {parentNotifier});

    ref.redux(reduxProvider).dispatch(_WatchDependencyAction());

    expect(ref.read(_switchProvider), true);
    expect(ref.read(_counterAProvider), 10);
    expect(ref.read(_counterBProvider), 20);
    expect(ref.read(reduxProvider).counter, 10);

    // Check dependency graph after WatchAction
    expect(parentNotifier.dependencies, isEmpty);
    expect(parentNotifier.dependents, {reduxNotifier});
    expect(switchNotifier.dependencies, isEmpty);
    expect(switchNotifier.dependents, {reduxNotifier});
    expect(notifierA.dependencies, isEmpty);
    expect(notifierA.dependents, {reduxNotifier});
    expect(notifierB.dependencies, isEmpty);
    expect(notifierB.dependents, isEmpty);
    expect(reduxNotifier.dependencies, {
      parentNotifier, // make sure to handle decoy (see action)
      switchNotifier,
      notifierA,
    });
    expect(reduxNotifier.dependents, isEmpty);

    // Change state
    ref.notifier(_counterAProvider).setState((old) => old + 1);
    await skipAllMicrotasks();

    expect(ref.read(_switchProvider), true);
    expect(ref.read(_counterAProvider), 11);
    expect(ref.read(_counterBProvider), 20);
    expect(ref.read(reduxProvider).counter, 11);

    // Watch new provider
    ref.notifier(_switchProvider).setState((_) => false);
    await skipAllMicrotasks();

    expect(ref.read(_switchProvider), false);
    expect(ref.read(_counterAProvider), 11);
    expect(ref.read(_counterBProvider), 20);
    expect(ref.read(reduxProvider).counter, 20);

    // Check dependency graph after switching
    expect(parentNotifier.dependencies, isEmpty);
    expect(parentNotifier.dependents, {reduxNotifier});
    expect(switchNotifier.dependencies, isEmpty);
    expect(switchNotifier.dependents, {reduxNotifier});
    expect(notifierA.dependencies, isEmpty);
    expect(notifierA.dependents, isEmpty);
    expect(notifierB.dependencies, isEmpty);
    expect(notifierB.dependents, {reduxNotifier});
    expect(reduxNotifier.dependencies, {
      parentNotifier, // make sure to handle decoy (see action)
      switchNotifier,
      notifierB,
    });
    expect(reduxNotifier.dependents, isEmpty);

    // Change state
    observer.start(clearHistory: true);
    ref.notifier(_counterBProvider).setState((old) => old + 1);
    await skipAllMicrotasks();
    observer.stop();

    expect(ref.read(_switchProvider), false);
    expect(ref.read(_counterAProvider), 11);
    expect(ref.read(_counterBProvider), 21);
    expect(ref.read(reduxProvider).counter, 21);
    expect(observer.dispatchedActions, [
      isA<WatchUpdateAction>(),
    ]);

    // Change state of old provider (should not trigger a rebuild)
    observer.start(clearHistory: true);
    ref.notifier(_counterAProvider).setState((old) => old + 1);
    await skipAllMicrotasks();
    observer.stop();

    expect(ref.read(_switchProvider), false);
    expect(ref.read(_counterAProvider), 12);
    expect(ref.read(_counterBProvider), 21);
    expect(ref.read(reduxProvider).counter, 21);
    expect(observer.dispatchedActions, isEmpty);
  });

  test('Should dispose WatchAction manually', () async {
    final observer = RefenaHistoryObserver.only(
      actionDispatched: true,
      change: true,
    );

    final ref = RefenaContainer(
      observers: [observer],
    );

    final reduxProvider = ReduxProvider<_ReduxNotifier, _ReduxState>((ref) {
      return _ReduxNotifier();
    });

    final sub = ref.redux(reduxProvider).dispatchTakeResult(_WatchAction());
    expect(ref.read(_counterAProvider), 10);
    expect(ref.read(reduxProvider).counter, 10);
    expect(ref.read(reduxProvider).name, '');

    ref.notifier(_counterAProvider).setState((_) => 20);
    await skipAllMicrotasks();
    expect(ref.read(_counterAProvider), 20);
    expect(ref.read(reduxProvider).counter, 20);
    expect(ref.read(reduxProvider).name, '');

    sub.cancel();

    ref.notifier(_counterAProvider).setState((_) => 30);
    await skipAllMicrotasks();
    expect(ref.read(_counterAProvider), 30);
    expect(ref.read(reduxProvider).counter, 20);
    expect(ref.read(reduxProvider).name, '');
  });

  test('Should dispose WatchAction on notifier dispose', () async {
    final observer = RefenaHistoryObserver.only(
      actionDispatched: true,
      change: true,
    );

    final ref = RefenaContainer(
      observers: [observer],
    );

    final reduxProvider = ReduxProvider<_ReduxNotifier, _ReduxState>((ref) {
      return _ReduxNotifier();
    });

    final sub = ref.redux(reduxProvider).dispatchTakeResult(_WatchAction());
    expect(ref.read(_counterAProvider), 10);
    expect(ref.read(reduxProvider).counter, 10);
    expect(ref.read(reduxProvider).name, '');

    ref.notifier(_counterAProvider).setState((_) => 20);
    await skipAllMicrotasks();
    expect(ref.read(_counterAProvider), 20);
    expect(ref.read(reduxProvider).counter, 20);
    expect(ref.read(reduxProvider).name, '');
    expect(sub.disposed, false);

    ref.dispose(reduxProvider);
    expect(ref.read(_counterAProvider), 20);
    expect(ref.read(reduxProvider).counter, 0);
    expect(ref.read(reduxProvider).name, '');
    expect(sub.disposed, true);

    ref.notifier(_counterAProvider).setState((_) => 30);
    await skipAllMicrotasks();
    expect(ref.read(_counterAProvider), 30);
    expect(ref.read(reduxProvider).counter, 0);
    expect(ref.read(reduxProvider).name, '');
  });
}

final _switchProvider = StateProvider((ref) => true);
final _parentProvider = StateProvider((ref) => 0);
final _counterAProvider = StateProvider((ref) => 10);
final _counterBProvider = StateProvider((ref) => 20);

class _ReduxState {
  final int counter;
  final String name;

  _ReduxState({
    required this.counter,
    required this.name,
  });
}

class _ReduxNotifier extends ReduxNotifier<_ReduxState> {
  @override
  _ReduxState init() => _ReduxState(
        counter: 0,
        name: '',
      );
}

class _UpdateNameAction extends ReduxAction<_ReduxNotifier, _ReduxState> {
  final String name;

  _UpdateNameAction(this.name);

  @override
  _ReduxState reduce() {
    return _ReduxState(
      counter: state.counter,
      name: name,
    );
  }
}

class _WatchAction extends WatchAction<_ReduxNotifier, _ReduxState> {
  @override
  _ReduxState reduce() {
    return _ReduxState(
      counter: ref.watch(_counterAProvider),
      name: state.name,
    );
  }
}

class _WatchDependencyAction extends WatchAction<_ReduxNotifier, _ReduxState> {
  @override
  _ReduxState reduce() {
    final b = ref.watch(_switchProvider);
    final int counter;
    if (b) {
      ref.watch(_parentProvider); // decoy
      counter = ref.watch(_counterAProvider);
    } else {
      counter = ref.watch(_counterBProvider);
    }
    return _ReduxState(
      counter: counter,
      name: state.name,
    );
  }
}
