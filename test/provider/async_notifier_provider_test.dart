import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpie/riverpie.dart';

import '../util/skip_microtasks.dart';

void main() {
  test('Should read the value', () async {
    final notifier = _AsyncCounter(123);
    final provider =
        AsyncNotifierProvider<_AsyncCounter, int>((ref) => notifier);
    final observer = RiverpieHistoryObserver();
    final scope = RiverpieScope(
      observer: observer,
      child: Container(),
    );

    expect(scope.read(provider), AsyncSnapshot<int>.waiting());
    expect(await scope.future(provider), 123);
    expect(
      scope.read(provider),
      AsyncSnapshot.withData(ConnectionState.done, 123),
    );

    scope.notifier(provider).increment();

    // wait for the microtasks to be executed
    await skipAllMicrotasks();

    expect(scope.read(provider), AsyncSnapshot<int>.waiting());
    expect(
      scope.notifier(provider).prev,
      AsyncSnapshot.withData(ConnectionState.done, 123),
    );
    expect(await scope.future(provider), 124);

    // Check events
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: AsyncSnapshot<int>.waiting(),
      ),
      ChangeEvent(
        notifier: notifier,
        prev: AsyncSnapshot<int>.waiting(),
        next: AsyncSnapshot.withData(ConnectionState.done, 123),
        flagRebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        prev: AsyncSnapshot.withData(ConnectionState.done, 123),
        next: AsyncSnapshot<int>.waiting(),
        flagRebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        prev: AsyncSnapshot<int>.waiting(),
        next: AsyncSnapshot.withData(ConnectionState.done, 124),
        flagRebuild: [],
      ),
    ]);
  });

  test('Should cancel old future when new future is set', () async {
    final notifier = _AsyncCounter(123);
    final provider =
        AsyncNotifierProvider<_AsyncCounter, int>((ref) => notifier);
    final observer = RiverpieHistoryObserver();
    final scope = RiverpieScope(
      observer: observer,
      child: Container(),
    );

    expect(scope.read(provider), AsyncSnapshot<int>.waiting());
    expect(await scope.future(provider), 123);
    expect(
      scope.read(provider),
      AsyncSnapshot.withData(ConnectionState.done, 123),
    );

    scope.notifier(provider).setDelayed(11, const Duration(milliseconds: 50));

    await skipAllMicrotasks();

    expect(scope.read(provider), AsyncSnapshot<int>.waiting());
    expect(
      scope.notifier(provider).prev,
      AsyncSnapshot.withData(ConnectionState.done, 123),
    );

    // Set it again, it should cancel the previous future
    scope.notifier(provider).setDelayed(12, const Duration(milliseconds: 50));

    await skipAllMicrotasks();

    expect(scope.read(provider), AsyncSnapshot<int>.waiting());
    expect(
      scope.notifier(provider).prev,
      AsyncSnapshot<int>.waiting(),
    );

    expect(await scope.future(provider), 12);

    // Check events
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: AsyncSnapshot<int>.waiting(),
      ),
      ChangeEvent(
        notifier: notifier,
        prev: AsyncSnapshot<int>.waiting(),
        next: AsyncSnapshot.withData(ConnectionState.done, 123),
        flagRebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        prev: AsyncSnapshot.withData(ConnectionState.done, 123),
        next: AsyncSnapshot<int>.waiting(),
        flagRebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        prev: AsyncSnapshot<int>.waiting(),
        next: AsyncSnapshot<int>.waiting(),
        flagRebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        prev: AsyncSnapshot<int>.waiting(),
        next: AsyncSnapshot.withData(ConnectionState.done, 12),
        flagRebuild: [],
      ),
    ]);
  });
}

class _AsyncCounter extends AsyncNotifier<int> {
  final int initialValue;

  _AsyncCounter(this.initialValue);

  @override
  Future<int> init() async {
    await Future.delayed(Duration(milliseconds: 50));
    return initialValue;
  }

  void increment() async {
    final prev = await future;
    future = Future.delayed(
      Duration(milliseconds: 50),
      () => prev + 1,
    );
  }

  void setDelayed(int newValue, Duration delay) async {
    future = Future.delayed(delay, () => newValue);
  }
}
