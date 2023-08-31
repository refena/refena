import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

import '../util/skip_microtasks.dart';

void main() {
  group('toString', () {
    test(ImmutableNotifier, () {
      final ref = RiverpieContainer();
      final provider = Provider((ref) => 11);

      expect(
        ref.anyNotifier(provider).toString(),
        'ImmutableNotifier<int>(state: 11)',
      );
    });

    test(FutureProviderNotifier, () async {
      final ref = RiverpieContainer();
      final provider = FutureProvider((ref) async => 22);
      final notifier = ref.anyNotifier(provider);

      expect(
        notifier.toString(),
        'FutureProviderNotifier<int>(state: AsyncLoading<int>)',
      );
      await skipAllMicrotasks();
      expect(
        notifier.toString(),
        'FutureProviderNotifier<int>(state: AsyncData<int>(22))',
      );
    });

    test(Notifier, () {
      expect(_Counter().toString(), '_Counter(state: uninitialized)');

      final ref = RiverpieContainer();
      final provider = NotifierProvider((ref) => _Counter());

      expect(ref.notifier(provider).toString(), '_Counter(state: 33)');
    });

    test(PureNotifier, () {
      final ref = RiverpieContainer();
      final provider = NotifierProvider((ref) => _PureCounter());

      expect(ref.notifier(provider).toString(), '_PureCounter(state: 44)');
    });

    test(AsyncNotifier, () async {
      final ref = RiverpieContainer();
      final provider = AsyncNotifierProvider((ref) => _AsyncCounter());
      final notifier = ref.notifier(provider);

      expect(notifier.toString(), '_AsyncCounter(state: AsyncLoading<int>)');
      await skipAllMicrotasks();
      expect(notifier.toString(), '_AsyncCounter(state: AsyncData<int>(55))');
    });

    test(StateNotifier, () {
      final ref = RiverpieContainer();
      final provider = StateProvider((ref) => 66);

      expect(
        ref.notifier(provider).toString(),
        'StateNotifier<int>(state: 66)',
      );
    });

    test(ViewProviderNotifier, () {
      final ref = RiverpieContainer();
      final provider = ViewProvider((ref) => 77);

      expect(
        ref.anyNotifier(provider).toString(),
        'ViewProviderNotifier<int>(state: 77)',
      );
    });
  });

  group('dispose', () {
    test('Should call dispose on Notifier', () {
      final ref = RiverpieContainer();
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
