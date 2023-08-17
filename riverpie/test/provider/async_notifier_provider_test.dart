import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

import '../util/skip_microtasks.dart';

void main() {
  test('Should read the value', () async {
    final notifier = _AsyncCounter(123);
    final provider =
        AsyncNotifierProvider<_AsyncCounter, int>((ref) => notifier);
    final observer = RiverpieHistoryObserver.all();
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(provider), AsyncValue<int>.loading());
    expect(await ref.future(provider), 123);
    expect(
      ref.read(provider),
      AsyncValue.withData(123),
    );

    ref.notifier(provider).increment();

    // wait for the microtasks to be executed
    await skipAllMicrotasks();

    expect(ref.read(provider), AsyncValue<int>.loading());
    expect(
      ref.notifier(provider).prev,
      AsyncValue.withData(123),
    );
    expect(await ref.future(provider), 124);

    // Check events
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: AsyncValue<int>.loading(),
      ),
      ChangeEvent(
        notifier: notifier,
        event: null,
        prev: AsyncValue<int>.loading(),
        next: AsyncValue.withData(123),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        event: null,
        prev: AsyncValue.withData(123),
        next: AsyncValue<int>.loading(),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        event: null,
        prev: AsyncValue<int>.loading(),
        next: AsyncValue.withData(124),
        rebuild: [],
      ),
    ]);
  });

  test('Should cancel old future when new future is set', () async {
    final notifier = _AsyncCounter(123);
    final provider =
        AsyncNotifierProvider<_AsyncCounter, int>((ref) => notifier);
    final observer = RiverpieHistoryObserver.all();
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(provider), AsyncValue<int>.loading());
    expect(await ref.future(provider), 123);
    expect(
      ref.read(provider),
      AsyncValue.withData(123),
    );

    ref.notifier(provider).setDelayed(11, const Duration(milliseconds: 50));

    await skipAllMicrotasks();

    expect(ref.read(provider), AsyncValue<int>.loading());
    expect(
      ref.notifier(provider).prev,
      AsyncValue.withData(123),
    );

    // Set it again, it should cancel the previous future
    ref.notifier(provider).setDelayed(12, const Duration(milliseconds: 50));

    await skipAllMicrotasks();

    expect(ref.read(provider), AsyncValue<int>.loading());
    expect(
      ref.notifier(provider).prev,
      AsyncValue<int>.loading(),
    );

    expect(await ref.future(provider), 12);

    // Check events
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: AsyncValue<int>.loading(),
      ),
      ChangeEvent(
        notifier: notifier,
        event: null,
        prev: AsyncValue<int>.loading(),
        next: AsyncValue.withData(123),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        event: null,
        prev: AsyncValue.withData(123),
        next: AsyncValue<int>.loading(),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        event: null,
        prev: AsyncValue<int>.loading(),
        next: AsyncValue<int>.loading(),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        event: null,
        prev: AsyncValue<int>.loading(),
        next: AsyncValue.withData(12),
        rebuild: [],
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
    await setState((snapshot) async {
      await Future.delayed(const Duration(milliseconds: 50));
      final curr = await snapshot.currFuture;
      return curr + 1;
    });
  }

  void setDelayed(int newValue, Duration delay) async {
    await setState((_) async {
      await Future.delayed(delay);
      return newValue;
    });
  }
}
