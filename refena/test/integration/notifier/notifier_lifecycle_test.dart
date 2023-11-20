import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  test('Should call postInit', () {
    final observer = RefenaHistoryObserver.only(
      providerInit: true,
      change: true,
    );
    final ref = RefenaContainer(
      observers: [observer],
    );

    final provider = NotifierProvider<_Counter, int>((ref) => _Counter());

    expect(ref.read(provider), 300);

    // Check events
    final notifier = ref.notifier(provider);
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: 100,
      ),
      ChangeEvent(
        notifier: notifier,
        action: null,
        prev: 100,
        next: 300,
        rebuild: [],
      ),
    ]);
  });

  test('Should call dispose on Notifier', () {
    final ref = RefenaContainer();
    bool called = false;
    final provider = NotifierProvider<_DisposableCounter, int>((ref) {
      return _DisposableCounter(() => called = true);
    });

    expect(ref.read(provider), 66);
    expect(called, false);

    ref.notifier(provider).increment();
    expect(ref.read(provider), 67);
    expect(called, false);

    ref.dispose(provider);
    expect(ref.read(provider), 66);
    expect(called, true);
  });

  test('Disposing a notifier should dispose its dependencies', () {
    final ref = RefenaContainer();

    final providerA = StateProvider((ref) => 10);
    final providerB = StateProvider((ref) {
      return ref.read(providerA) + 1;
    });

    final notifierA = ref.notifier(providerA);
    final notifierB = ref.notifier(providerB);

    expect(ref.read(providerA), 10);
    expect(ref.read(providerB), 11);

    expect(notifierA.dependencies, isEmpty);
    expect(notifierA.dependents, {notifierB});
    expect(notifierB.dependencies, {notifierA});
    expect(notifierB.dependents, isEmpty);

    notifierA.setState((old) => old + 1);
    notifierB.setState((old) => old + 10);

    expect(ref.read(providerA), 11);
    expect(ref.read(providerB), 21);

    ref.dispose(providerA);

    expect(ref.read(providerA), 10);
    expect(ref.read(providerB), 11);
  });
}

class _Counter extends Notifier<int> {
  @override
  int init() => 100;

  @override
  void postInit() {
    state += 200;
  }
}

class _DisposableCounter extends Notifier<int> {
  final void Function() onDispose;

  _DisposableCounter(this.onDispose);

  @override
  int init() => 66;

  void increment() {
    state++;
  }

  @override
  void dispose() {
    onDispose();
  }
}
