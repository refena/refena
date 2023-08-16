import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpie/riverpie.dart';

void main() {
  group(AsyncNotifierProvider, () {
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
      await Future.delayed(Duration.zero);

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
}
