import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Single provider test', () {
    final notifier = _Counter(123);
    final provider = NotifierProvider<_Counter, int>((ref) => notifier);
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), 123);

    ref.notifier(provider).increment();

    expect(ref.read(provider), 124);

    // Check events
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: 123,
      ),
      ChangeEvent(
        notifier: notifier,
        action: null,
        prev: 123,
        next: 124,
        rebuild: [],
      ),
    ]);
  });

  test('Multiple provider test', () {
    final notifierA = _Counter(1);
    final notifierB = _Counter(2);
    final providerA = NotifierProvider<_Counter, int>((ref) => notifierA);
    final providerB = NotifierProvider<_Counter, int>((ref) => notifierB);
    final providerC = NotifierProvider<_Sum, int>((ref) {
      return _Sum(
        initialValue: 3,
        providerA: ref.notifier(providerA),
        providerB: ref.notifier(providerB),
      );
    });
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(providerC), 3);
    expect(ref.notifier(providerC).getSum(), 6);

    ref.notifier(providerA).increment();

    expect(ref.read(providerA), 2);
    expect(ref.read(providerC), 3);
    expect(ref.notifier(providerC).getSum(), 7);

    // Check events
    final notifierC = ref.notifier(providerC);
    expect(observer.history, [
      ProviderInitEvent(
        provider: providerA,
        notifier: notifierA,
        cause: ProviderInitCause.access,
        value: 1,
      ),
      ProviderInitEvent(
        provider: providerB,
        notifier: notifierB,
        cause: ProviderInitCause.access,
        value: 2,
      ),
      ProviderInitEvent(
        provider: providerC,
        notifier: notifierC,
        cause: ProviderInitCause.access,
        value: 3,
      ),
      ChangeEvent(
        notifier: notifierA,
        action: null,
        prev: 1,
        next: 2,
        rebuild: [],
      ),
    ]);
  });

  test('Should trigger onChanged', () async {
    final provider = NotifierProvider<_Counter, int>(
      (ref) => _Counter(123),
      onChanged: (prev, next, ref) => ref.message('Change from $prev to $next'),
    );
    final observer = RefenaHistoryObserver.only(
      message: true,
    );
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), 123);

    ref.notifier(provider).increment();
    await skipAllMicrotasks();

    expect(ref.read(provider), 124);
    expect(observer.messages, [
      'Change from 123 to 124',
    ]);
  });
}

class _Counter extends Notifier<int> {
  final int initialValue;

  _Counter(this.initialValue);

  @override
  int init() => initialValue;

  void increment() {
    state++;
  }
}

class _Sum extends Notifier<int> {
  final int initialValue;
  final _Counter providerA;
  final _Counter providerB;

  _Sum({
    required this.initialValue,
    required this.providerA,
    required this.providerB,
  });

  @override
  int init() => initialValue;

  int getSum() => providerA.state + providerB.state + state;
}
