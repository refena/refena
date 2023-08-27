import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  test('Should change state', () {
    final notifier = _Counter();
    final provider = ReduxProvider<_Counter, int>((ref) => notifier);
    final observer = RiverpieHistoryObserver.all();
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(provider), 123);

    // ignore: invalid_use_of_protected_member
    final addResult = ref.redux(provider).notifier.dispatch(_AddAction(2));
    expect(addResult, 125);
    expect(ref.read(provider), 125);

    final subtractResult = ref.redux(provider).dispatch(_SubtractAction(5));
    expect(subtractResult, 120);
    expect(ref.read(provider), 120);

    // Check events
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: 123,
      ),
      ActionDispatchedEvent(
        debugOrigin: '_Counter',
        notifier: notifier,
        action: _AddAction(2),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _AddAction(2),
        prev: 123,
        next: 125,
        rebuild: [],
      ),
      ActionDispatchedEvent(
        debugOrigin: 'RiverpieContainer',
        notifier: notifier,
        action: _SubtractAction(5),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _SubtractAction(5),
        prev: 125,
        next: 120,
        rebuild: [],
      ),
    ]);
  });

  test('Should trigger lifecycle methods', () {
    final notifier = _Counter();
    final provider = ReduxProvider<_Counter, int>((ref) => notifier);
    final observer = RiverpieHistoryObserver(HistoryObserverConfig(
      saveChangeEvents: true,
      saveActionDispatchedEvents: true,
    ));

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
        notifier: notifier,
        action: _LifeCycleAction(10),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_LifeCycleAction',
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
