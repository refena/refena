import 'dart:async';

import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  test('Should await event', () async {
    final notifier = _AsyncCounter();
    final provider = ReduxProvider<_AsyncCounter, int>((ref) => notifier);
    final observer = RiverpieHistoryObserver();
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(provider), 123);

    // ignore: unawaited_futures
    final s0Result =
        ref.redux(provider).dispatchAsyncWithResult(_AsyncSubtractAction(5));
    expect(s0Result, isA<Future<(int, String)>>());
    expect(ref.read(provider), 123);
    final addResult = ref.redux(provider).dispatch(_AsyncAddAction(2));
    expect(addResult, 125);
    expect(ref.read(provider), 125);

    await Future.delayed(Duration(milliseconds: 100));
    expect(ref.read(provider), 120);

    final (newState, result) = await ref
        .redux(provider)
        .notifier
        // ignore: invalid_use_of_protected_member
        .dispatchAsyncWithResult(_AsyncSubtractAction(5));
    expect(newState, 115);
    expect(result, 'test-5');
    expect(ref.read(provider), 115);

    final result2 = await ref
        .redux(provider)
        .dispatchAsyncTakeResult(_AsyncSubtractAction(15));
    expect(result2, 'test-15');
    expect(ref.read(provider), 100);

    // Check events
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RiverpieContainer',
        notifier: notifier,
        action: _AsyncSubtractAction(5),
      ),
      ActionDispatchedEvent(
        debugOrigin: 'RiverpieContainer',
        notifier: notifier,
        action: _AsyncAddAction(2),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _AsyncAddAction(2),
        prev: 123,
        next: 125,
        rebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        action: _AsyncSubtractAction(5),
        prev: 125,
        next: 120,
        rebuild: [],
      ),
      ActionDispatchedEvent(
        debugOrigin: '_AsyncCounter',
        notifier: notifier,
        action: _AsyncSubtractAction(5),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _AsyncSubtractAction(5),
        prev: 120,
        next: 115,
        rebuild: [],
      ),
      ActionDispatchedEvent(
        debugOrigin: 'RiverpieContainer',
        notifier: notifier,
        action: _AsyncSubtractAction(15),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _AsyncSubtractAction(15),
        prev: 115,
        next: 100,
        rebuild: [],
      ),
    ]);
  });
}

class _AsyncCounter extends ReduxNotifier<int> {
  @override
  int init() => 123;
}

class _AsyncAddAction extends ReduxAction<_AsyncCounter, int> {
  final int amount;

  _AsyncAddAction(this.amount);

  @override
  int reduce() {
    return state + amount;
  }

  @override
  bool operator ==(Object other) {
    return other is _AsyncAddAction && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;
}

class _AsyncSubtractAction
    extends AsyncReduxActionWithResult<_AsyncCounter, int, String> {
  final int amount;

  _AsyncSubtractAction(this.amount);

  @override
  Future<(int, String)> reduce() async {
    await Future.delayed(Duration(milliseconds: 50));
    return (state - amount, 'test-$amount');
  }

  @override
  bool operator ==(Object other) {
    return other is _AsyncSubtractAction && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;
}
