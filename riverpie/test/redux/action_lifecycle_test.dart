import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  late RiverpieHistoryObserver observer;

  setUp(() {
    observer = RiverpieHistoryObserver.only(
      change: true,
      actionDispatched: true,
      actionError: true,
    );
  });

  test('Should trigger lifecycle methods', () {
    final notifier = _Counter();
    final provider = ReduxProvider<_Counter, int>((ref) => notifier);
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(provider), 123);

    final result = ref.redux(provider).dispatch(_LifeCycleAction(10));
    expect(result, -5);

    // The after() method is called after the reduce() method,
    // hence, the state increased by 10.
    expect(ref.read(provider), 5);

    // Check events
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RiverpieContainer',
        debugOriginRef: ref,
        notifier: notifier,
        action: _LifeCycleAction(10),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_LifeCycleAction',
        debugOriginRef: _LifeCycleAction(10),
        notifier: notifier,
        action: _SetCounterAction(0),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _SetCounterAction(0),
        prev: 123,
        next: 0,
        rebuild: [],
      ),
      ActionDispatchedEvent(
        debugOrigin: '_LifeCycleAction',
        debugOriginRef: _LifeCycleAction(10),
        notifier: notifier,
        action: _SubtractAction(10),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _SubtractAction(10),
        prev: 0,
        next: -10,
        rebuild: [],
      ),
      ActionDispatchedEvent(
        debugOrigin: '_LifeCycleAction',
        debugOriginRef: _LifeCycleAction(10),
        notifier: notifier,
        action: _SubtractAction(10),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _SubtractAction(10),
        prev: -10,
        next: -20,
        rebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        action: _LifeCycleAction(10),
        prev: -20,
        next: -5,
        rebuild: [],
      ),
      ActionDispatchedEvent(
        debugOrigin: '_LifeCycleAction',
        debugOriginRef: _LifeCycleAction(10),
        notifier: notifier,
        action: _AddAction(10),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _AddAction(10),
        prev: -5,
        next: 5,
        rebuild: [],
      ),
    ]);
  });

  test('Should handle errors in before', () {
    final notifier = _Counter();
    final provider = ReduxProvider<_Counter, int>((ref) => notifier);
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(provider), 123);

    expect(
      () => ref.redux(provider).dispatch(_ErrorInBeforeAction()),
      throwsA(isA<String>()),
    );

    // The after() method should still produce a side effect
    expect(ref.read(provider), 124);

    // Check events
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RiverpieContainer',
        debugOriginRef: ref,
        notifier: notifier,
        action: _ErrorInBeforeAction(),
      ),
      ActionErrorEvent(
        action: _ErrorInBeforeAction(),
        lifecycle: ActionLifecycle.before,
        error: 'Error in before',
        stackTrace: StackTrace.fromString(''),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_ErrorInBeforeAction',
        debugOriginRef: _ErrorInBeforeAction(),
        notifier: notifier,
        action: _AddAction(1),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _AddAction(1),
        prev: 123,
        next: 124,
        rebuild: [],
      ),
    ]);
  });

  test('Should handle errors in reduce', () {
    final notifier = _Counter();
    final provider = ReduxProvider<_Counter, int>((ref) => notifier);
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(provider), 123);

    expect(
      () => ref.redux(provider).dispatch(_ErrorInReduceAction()),
      throwsA(isA<String>()),
    );

    // The after() method should still produce a side effect
    expect(ref.read(provider), 122);

    // Check events
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RiverpieContainer',
        debugOriginRef: ref,
        notifier: notifier,
        action: _ErrorInReduceAction(),
      ),
      ActionErrorEvent(
        action: _ErrorInReduceAction(),
        lifecycle: ActionLifecycle.reduce,
        error: 'Error in reduce',
        stackTrace: StackTrace.fromString(''),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_ErrorInReduceAction',
        debugOriginRef: _ErrorInReduceAction(),
        notifier: notifier,
        action: _SubtractAction(1),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _SubtractAction(1),
        prev: 123,
        next: 122,
        rebuild: [],
      ),
    ]);
  });

  test('Should handle errors in after', () {
    final notifier = _Counter();
    final provider = ReduxProvider<_Counter, int>((ref) => notifier);
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(provider), 123);

    expect(
      ref.redux(provider).dispatch(_ErrorInAfterAction()),
      133,
    );

    // The reduce() method should still produce a side effect
    expect(ref.read(provider), 133);

    // Check events
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RiverpieContainer',
        debugOriginRef: ref,
        notifier: notifier,
        action: _ErrorInAfterAction(),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _ErrorInAfterAction(),
        prev: 123,
        next: 133,
        rebuild: [],
      ),
      ActionErrorEvent(
        action: _ErrorInAfterAction(),
        lifecycle: ActionLifecycle.after,
        error: 'Error in after',
        stackTrace: StackTrace.fromString(''),
      ),
    ]);
  });
}

final counterProvider = ReduxProvider<_Counter, int>((ref) => _Counter());

class _Counter extends ReduxNotifier<int> {
  @override
  int init() => 123;
}

class _AddAction extends ReduxAction<_Counter, int> {
  final int amount;

  _AddAction(this.amount);

  @override
  int reduce() {
    return state + amount;
  }

  @override
  bool operator ==(Object other) {
    return other is _AddAction && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;
}

class _SubtractAction extends ReduxAction<_Counter, int> {
  final int amount;

  _SubtractAction(this.amount);

  @override
  int reduce() {
    return state - amount;
  }

  @override
  bool operator ==(Object other) {
    return other is _SubtractAction && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;
}

class _LifeCycleAction extends ReduxAction<_Counter, int> {
  final int amount;

  _LifeCycleAction(this.amount);

  @override
  void before() {
    dispatch(_SetCounterAction(0));
  }

  @override
  int reduce() {
    return state + 5;
  }

  @override
  void after() {
    dispatch(_AddAction(amount));
  }

  @override
  int wrapReduce() {
    dispatch(_SubtractAction(amount));
    final newState = reduce();
    dispatch(_SubtractAction(amount)); // has no effect
    return newState;
  }

  @override
  bool operator ==(Object other) {
    return other is _LifeCycleAction && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;
}

class _SetCounterAction extends ReduxAction<_Counter, int> {
  final int value;

  _SetCounterAction(this.value);

  @override
  int reduce() {
    return value;
  }

  @override
  bool operator ==(Object other) {
    return other is _SetCounterAction && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

class _ErrorInBeforeAction extends ReduxAction<_Counter, int> {
  @override
  void before() {
    throw 'Error in before';
  }

  @override
  int reduce() {
    return state + 1;
  }

  @override
  void after() {
    // Should still be called
    dispatch(_AddAction(1));
  }

  @override
  bool operator ==(Object other) {
    return other is _ErrorInBeforeAction;
  }

  @override
  int get hashCode => 0;
}

class _ErrorInReduceAction extends ReduxAction<_Counter, int> {
  @override
  int reduce() {
    throw 'Error in reduce';
  }

  @override
  void after() {
    // Should still be called
    dispatch(_SubtractAction(1));
  }

  @override
  bool operator ==(Object other) {
    return other is _ErrorInReduceAction;
  }

  @override
  int get hashCode => 0;
}

class _ErrorInAfterAction extends ReduxAction<_Counter, int> {
  @override
  int reduce() {
    return state + 10;
  }

  @override
  void after() {
    throw 'Error in after';
  }

  @override
  bool operator ==(Object other) {
    return other is _ErrorInAfterAction;
  }

  @override
  int get hashCode => 0;
}
