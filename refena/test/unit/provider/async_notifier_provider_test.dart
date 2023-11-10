import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Should read the value', () async {
    final notifier = _AsyncCounter(123);
    final provider =
        AsyncNotifierProvider<_AsyncCounter, int>((ref) => notifier);
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), AsyncValue<int>.loading());
    expect(await ref.future(provider), 123);
    expect(
      ref.read(provider),
      AsyncValue.data(123),
    );

    ref.notifier(provider).increment();

    // wait for the microtasks to be executed
    await skipAllMicrotasks();

    expect(ref.read(provider), AsyncValue<int>.loading(123));
    expect(
      ref.notifier(provider).prev,
      123,
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
        action: null,
        prev: AsyncValue<int>.loading(),
        next: AsyncValue.data(123),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        action: null,
        prev: AsyncValue.data(123),
        next: AsyncValue<int>.loading(123),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        action: null,
        prev: AsyncValue<int>.loading(123),
        next: AsyncValue.data(124),
        rebuild: [],
      ),
    ]);
  });

  test('Should cancel old future when new future is set', () async {
    final notifier = _AsyncCounter(123);
    final provider =
        AsyncNotifierProvider<_AsyncCounter, int>((ref) => notifier);
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), AsyncValue<int>.loading());
    expect(await ref.future(provider), 123);
    expect(
      ref.read(provider),
      AsyncValue.data(123),
    );

    ref.notifier(provider).setDelayed(11, const Duration(milliseconds: 50));

    await skipAllMicrotasks();

    expect(ref.read(provider), AsyncValue<int>.loading(123));
    expect(
      ref.notifier(provider).prev,
      123,
    );

    // Set it again, it should cancel the previous future
    ref.notifier(provider).setDelayed(12, const Duration(milliseconds: 50));

    await skipAllMicrotasks();

    expect(ref.read(provider), AsyncValue<int>.loading(123));
    expect(
      ref.notifier(provider).prev,
      123,
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
        action: null,
        prev: AsyncValue<int>.loading(),
        next: AsyncValue.data(123),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        action: null,
        prev: AsyncValue.data(123),
        next: AsyncValue<int>.loading(123),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        action: null,
        prev: AsyncValue<int>.loading(123),
        next: AsyncValue.data(12),
        rebuild: [],
      ),
    ]);
  });

  test('Should trigger onChanged', () async {
    final provider = AsyncNotifierProvider<_AsyncCounter, int>(
      (ref) => _AsyncCounter(123),
      onChanged: (prev, next, ref) => ref.message('Change from $prev to $next'),
    );
    final observer = RefenaHistoryObserver.only(
      message: true,
    );
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), AsyncValue<int>.loading());
    expect(await ref.future(provider), 123);
    expect(
      ref.read(provider),
      AsyncValue.data(123),
    );
    expect(observer.messages, isEmpty);

    await skipAllMicrotasks();

    expect(observer.messages, [
      'Change from AsyncLoading<int> to AsyncData<int>(123)',
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
