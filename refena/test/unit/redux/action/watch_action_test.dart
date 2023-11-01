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

    expect(ref.read(_counterProvider), 10);
    expect(ref.read(_reduxProvider).counter, 0);
    expect(ref.read(_reduxProvider).name, '');

    ref.redux(_reduxProvider).dispatch(_WatchAction());
    expect(ref.read(_counterProvider), 10);
    expect(ref.read(_reduxProvider).counter, 10);
    expect(ref.read(_reduxProvider).name, '');

    ref.redux(_reduxProvider).dispatch(_UpdateNameAction('test'));
    await skipAllMicrotasks();
    expect(ref.read(_counterProvider), 10);
    expect(ref.read(_reduxProvider).counter, 10);
    expect(ref.read(_reduxProvider).name, 'test');
    expect(observer.dispatchedActions.length, 2);
    expect(observer.dispatchedActions, [
      isA<_WatchAction>(),
      isA<_UpdateNameAction>(),
    ]);

    ref.notifier(_counterProvider).setState((_) => 20);
    await skipAllMicrotasks();
    expect(ref.read(_counterProvider), 20);
    expect(ref.read(_reduxProvider).counter, 20);
    expect(ref.read(_reduxProvider).name, 'test');
    expect(observer.dispatchedActions.length, 3);
    expect(observer.dispatchedActions, [
      isA<_WatchAction>(),
      isA<_UpdateNameAction>(),
      isA<WatchUpdateAction>(),
    ]);

    ref.redux(_reduxProvider).dispatch(_UpdateNameAction('test2'));
    await skipAllMicrotasks();
    expect(ref.read(_counterProvider), 20);
    expect(ref.read(_reduxProvider).counter, 20);
    expect(ref.read(_reduxProvider).name, 'test2');

    ref.notifier(_counterProvider).setState((_) => 30);
    await skipAllMicrotasks();
    expect(ref.read(_counterProvider), 30);
    expect(ref.read(_reduxProvider).counter, 30);
    expect(ref.read(_reduxProvider).name, 'test2');
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
    expect(watchUpdateEvent.debugOriginRef, ref.anyNotifier(_reduxProvider));
  });

  test('Should dispose WatchAction manually', () async {
    final observer = RefenaHistoryObserver.only(
      actionDispatched: true,
      change: true,
    );

    final ref = RefenaContainer(
      observers: [observer],
    );

    final sub = ref.redux(_reduxProvider).dispatchTakeResult(_WatchAction());
    expect(ref.read(_counterProvider), 10);
    expect(ref.read(_reduxProvider).counter, 10);
    expect(ref.read(_reduxProvider).name, '');

    ref.notifier(_counterProvider).setState((_) => 20);
    await skipAllMicrotasks();
    expect(ref.read(_counterProvider), 20);
    expect(ref.read(_reduxProvider).counter, 20);
    expect(ref.read(_reduxProvider).name, '');

    sub.cancel();

    ref.notifier(_counterProvider).setState((_) => 30);
    await skipAllMicrotasks();
    expect(ref.read(_counterProvider), 30);
    expect(ref.read(_reduxProvider).counter, 20);
    expect(ref.read(_reduxProvider).name, '');
  });

  test('Should dispose WatchAction on notifier dispose', () async {
    final observer = RefenaHistoryObserver.only(
      actionDispatched: true,
      change: true,
    );

    final ref = RefenaContainer(
      observers: [observer],
    );

    final sub = ref.redux(_reduxProvider).dispatchTakeResult(_WatchAction());
    expect(ref.read(_counterProvider), 10);
    expect(ref.read(_reduxProvider).counter, 10);
    expect(ref.read(_reduxProvider).name, '');

    ref.notifier(_counterProvider).setState((_) => 20);
    await skipAllMicrotasks();
    expect(ref.read(_counterProvider), 20);
    expect(ref.read(_reduxProvider).counter, 20);
    expect(ref.read(_reduxProvider).name, '');
    expect(sub.disposed, false);

    ref.dispose(_reduxProvider);
    expect(ref.read(_counterProvider), 20);
    expect(ref.read(_reduxProvider).counter, 0);
    expect(ref.read(_reduxProvider).name, '');
    expect(sub.disposed, true);

    ref.notifier(_counterProvider).setState((_) => 30);
    await skipAllMicrotasks();
    expect(ref.read(_counterProvider), 30);
    expect(ref.read(_reduxProvider).counter, 0);
    expect(ref.read(_reduxProvider).name, '');
  });
}

final _counterProvider = StateProvider((ref) => 10);

final _reduxProvider = ReduxProvider<_ReduxNotifier, _ReduxState>(
  (ref) => _ReduxNotifier(),
);

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
      counter: ref.watch(_counterProvider),
      name: state.name,
    );
  }
}
