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

    bool beforeCalled = false;
    ref.redux(reduxProvider).dispatch(_WatchAction(
          onBefore: () => beforeCalled = true,
        ));
    expect(ref.read(_counterAProvider), 10);
    expect(ref.read(reduxProvider).counter, 10);
    expect(ref.read(reduxProvider).name, '');
    expect(beforeCalled, true);

    beforeCalled = false;
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
    expect(beforeCalled, false);

    beforeCalled = false;
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
    expect(beforeCalled, false);

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

    // Check initial dependency graph (it should not change)
    void checkDependencyGraph() {
      expect(parentNotifier.dependencies, isEmpty);
      expect(parentNotifier.dependents, {reduxNotifier});
      expect(switchNotifier.dependencies, isEmpty);
      expect(switchNotifier.dependents, isEmpty);
      expect(notifierA.dependencies, isEmpty);
      expect(notifierA.dependents, isEmpty);
      expect(notifierB.dependencies, isEmpty);
      expect(notifierB.dependents, isEmpty);
      expect(reduxNotifier.dependencies, {parentNotifier});
    }

    checkDependencyGraph();

    // Check listeners
    expect(parentNotifier.getListeners(), isEmpty);
    expect(switchNotifier.getListeners(), isEmpty);
    expect(notifierA.getListeners(), isEmpty);
    expect(notifierB.getListeners(), isEmpty);
    expect(reduxNotifier.getListeners(), isEmpty);

    final action = _WatchDependencyAction();
    ref.redux(reduxProvider).dispatch(action);

    expect(ref.read(_switchProvider), true);
    expect(ref.read(_counterAProvider), 10);
    expect(ref.read(_counterBProvider), 20);
    expect(ref.read(reduxProvider).counter, 10);

    // Check dependency graph after WatchAction
    checkDependencyGraph();

    // Check listeners
    expect(parentNotifier.getListeners(), [action]);
    expect(switchNotifier.getListeners(), [action]);
    expect(notifierA.getListeners(), [action]);
    expect(notifierB.getListeners(), isEmpty);
    expect(reduxNotifier.getListeners(), isEmpty);

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
    checkDependencyGraph();

    // Check listeners
    expect(parentNotifier.getListeners(), isEmpty);
    expect(switchNotifier.getListeners(), [action]);
    expect(notifierA.getListeners(), isEmpty);
    expect(notifierB.getListeners(), [action]);
    expect(reduxNotifier.getListeners(), isEmpty);

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

    bool disposeCalled = false;
    final sub = ref.redux(reduxProvider).dispatchTakeResult(_WatchAction(
          onDispose: () => disposeCalled = true,
        ));
    expect(ref.read(_counterAProvider), 10);
    expect(ref.read(reduxProvider).counter, 10);
    expect(ref.read(reduxProvider).name, '');
    expect(disposeCalled, false);
    expect(sub.disposed, false);

    // Change state (should trigger a rebuild)
    ref.notifier(_counterAProvider).setState((_) => 20);
    await skipAllMicrotasks();
    expect(ref.read(_counterAProvider), 20);
    expect(ref.read(reduxProvider).counter, 20);
    expect(ref.read(reduxProvider).name, '');
    expect(disposeCalled, false);
    expect(sub.disposed, false);

    sub.cancel();
    expect(disposeCalled, true);
    expect(sub.disposed, true);

    // Change state (should not trigger a rebuild)
    ref.notifier(_counterAProvider).setState((_) => 30);
    await skipAllMicrotasks();
    expect(ref.read(_counterAProvider), 30);
    expect(ref.read(reduxProvider).counter, 20);
    expect(ref.read(reduxProvider).name, '');
    expect(disposeCalled, true);
    expect(sub.disposed, true);
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

    bool disposeCalled = false;
    final sub = ref.redux(reduxProvider).dispatchTakeResult(_WatchAction(
          onDispose: () => disposeCalled = true,
        ));
    expect(ref.read(_counterAProvider), 10);
    expect(ref.read(reduxProvider).counter, 10);
    expect(ref.read(reduxProvider).name, '');
    expect(disposeCalled, false);
    expect(sub.disposed, false);

    ref.notifier(_counterAProvider).setState((_) => 20);
    await skipAllMicrotasks();
    expect(ref.read(_counterAProvider), 20);
    expect(ref.read(reduxProvider).counter, 20);
    expect(ref.read(reduxProvider).name, '');
    expect(disposeCalled, false);
    expect(sub.disposed, false);

    ref.dispose(reduxProvider);
    expect(ref.read(_counterAProvider), 20);
    expect(ref.read(reduxProvider).counter, 0);
    expect(ref.read(reduxProvider).name, '');
    expect(disposeCalled, true);
    expect(sub.disposed, true);

    ref.notifier(_counterAProvider).setState((_) => 30);
    await skipAllMicrotasks();
    expect(ref.read(_counterAProvider), 30);
    expect(ref.read(reduxProvider).counter, 0);
    expect(ref.read(reduxProvider).name, '');
  });

  test('Disposing temp provider should not dispose notifier', () async {
    final observer = RefenaHistoryObserver.only(
      providerDispose: true,
    );

    final ref = RefenaContainer(
      observers: [observer],
    );

    final reduxProvider = ReduxProvider<_ReduxNotifier, _ReduxState>((ref) {
      return _ReduxNotifier();
    });

    final action = _TempProviderAction();
    final sub = ref.redux(reduxProvider).dispatchTakeResult(action);

    final notifier = ref.notifier(reduxProvider);
    final tempNotifier = ref.notifier(action._tempProvider);
    expect(ref.read(reduxProvider).counter, 33);
    expect(ref.read(action._tempProvider), 33);
    expect(sub.disposed, false);
    expect(notifier.disposed, false);
    expect(tempNotifier.disposed, false);

    ref.notifier(action._tempProvider).setState((old) => old + 1);
    await skipAllMicrotasks();

    expect(ref.read(reduxProvider).counter, 34);
    expect(ref.read(action._tempProvider), 34);
    expect(sub.disposed, false);
    expect(notifier.disposed, false);
    expect(tempNotifier.disposed, false);

    sub.cancel();

    // Everything should be disposed except the notifier
    expect(ref.read(reduxProvider).counter, 34);
    expect(ref.read(action._tempProvider), 33); // reset to initial value
    expect(sub.disposed, true);
    expect(notifier.disposed, false);
    expect(tempNotifier.disposed, true);

    ref.dispose(reduxProvider);

    // Now the notifier should be disposed too
    expect(ref.read(reduxProvider).counter, 0);
    expect(notifier.disposed, true);
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
  final void Function()? onBefore;
  final void Function()? onDispose;

  _WatchAction({
    this.onBefore,
    this.onDispose,
  });

  @override
  void before() {
    onBefore?.call();
  }

  @override
  _ReduxState reduce() {
    return _ReduxState(
      counter: ref.watch(_counterAProvider),
      name: state.name,
    );
  }

  @override
  void dispose() {
    onDispose?.call();
    super.dispose();
  }
}

class _WatchDependencyAction extends WatchAction<_ReduxNotifier, _ReduxState> {
  @override
  _ReduxState reduce() {
    final b = ref.watch(_switchProvider);
    final int counter;
    if (b) {
      ref.watch(_parentProvider); // it is also notifier dependency
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

class _TempProviderAction extends WatchAction<_ReduxNotifier, _ReduxState> {
  late final _tempProvider = StateProvider((ref) => 33);

  @override
  _ReduxState reduce() {
    return _ReduxState(
      counter: ref.watch(_tempProvider),
      name: state.name,
    );
  }

  @override
  void dispose() {
    ref.dispose(_tempProvider);
    super.dispose();
  }
}
