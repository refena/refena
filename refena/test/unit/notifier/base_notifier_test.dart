import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  group('toString', () {
    test(ImmutableNotifier, () {
      final ref = RefenaContainer();
      final provider = Provider((ref) => 11);

      expect(
        ref.anyNotifier(provider).toString(),
        'ImmutableNotifier<int>(label: Provider<int>, state: 11)',
      );
    });

    test(FutureProviderNotifier, () async {
      final ref = RefenaContainer();
      final provider = FutureProvider((ref) async => 22);
      final notifier = ref.anyNotifier(provider);

      expect(
        notifier.toString(),
        'FutureProviderNotifier<int>(label: FutureProvider<int>, state: AsyncLoading<int>)',
      );
      await skipAllMicrotasks();
      expect(
        notifier.toString(),
        'FutureProviderNotifier<int>(label: FutureProvider<int>, state: AsyncData<int>(22))',
      );
    });

    test(Notifier, () {
      expect(_Counter().toString(),
          '_Counter(label: _Counter, state: uninitialized)');

      final ref = RefenaContainer();
      final provider = NotifierProvider((ref) => _Counter());

      expect(ref.notifier(provider).toString(),
          '_Counter(label: _Counter, state: 33)');
    });

    test(PureNotifier, () {
      final ref = RefenaContainer();
      final provider = NotifierProvider((ref) => _PureCounter());

      expect(ref.notifier(provider).toString(),
          '_PureCounter(label: _PureCounter, state: 44)');
    });

    test(AsyncNotifier, () async {
      final ref = RefenaContainer();
      final provider = AsyncNotifierProvider((ref) => _AsyncCounter());
      final notifier = ref.notifier(provider);

      expect(notifier.toString(),
          '_AsyncCounter(label: _AsyncCounter, state: AsyncLoading<int>)');
      await skipAllMicrotasks();
      expect(notifier.toString(),
          '_AsyncCounter(label: _AsyncCounter, state: AsyncData<int>(55))');
    });

    test(StateNotifier, () {
      final ref = RefenaContainer();
      final provider = StateProvider((ref) => 66);

      expect(
        ref.notifier(provider).toString(),
        'StateNotifier<int>(label: StateProvider<int>, state: 66)',
      );
    });

    test(ViewProviderNotifier, () {
      final ref = RefenaContainer();
      final provider = ViewProvider((ref) => 77);

      expect(
        ref.anyNotifier(provider).toString(),
        'ViewProviderNotifier<int>(label: ViewProvider<int>, state: 77)',
      );
    });
  });

  group('dispose', () {
    test('Should call dispose on Notifier', () {
      final ref = RefenaContainer();
      bool called = false;
      final provider = NotifierProvider((ref) {
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
  });
}

class _Counter extends Notifier<int> {
  @override
  int init() => 33;
}

class _PureCounter extends PureNotifier<int> {
  @override
  int init() => 44;
}

class _AsyncCounter extends AsyncNotifier<int> {
  @override
  Future<int> init() async => 55;
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
    super.dispose();
  }
}
