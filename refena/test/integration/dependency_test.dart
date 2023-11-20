import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../util/skip_microtasks.dart';

/// This file tests if the dependency tree is built correctly.
void main() {
  group(Provider, () {
    test('Should correctly build with one dependency', () {
      final container = RefenaContainer();

      final providerA = Provider((ref) => 123);
      final providerB = Provider((ref) => ref.read(providerA) + 1);

      // Sanity check
      expect(container.read(providerB), 124);

      final notifierA = container.anyNotifier(providerA);
      final notifierB = container.anyNotifier(providerB);

      expect(notifierA.dependencies, isEmpty);
      expect(notifierA.dependents, {notifierB});

      expect(notifierB.dependencies, {notifierA});
      expect(notifierB.dependents, isEmpty);
    });
  });

  group(FutureProvider, () {
    test('Should correctly build with one dependency', () async {
      final container = RefenaContainer();

      final providerA = Provider((ref) => 123);
      final providerB = FutureProvider((ref) async {
        return ref.read(providerA) + 1;
      });

      // Sanity check
      expect(await container.future(providerB), 124);

      final notifierA = container.anyNotifier(providerA);
      final notifierB = container.anyNotifier(providerB);

      expect(notifierA.dependencies, isEmpty);
      expect(notifierA.dependents, {notifierB});

      expect(notifierB.dependencies, {notifierA});
      expect(notifierB.dependents, isEmpty);
    });
  });

  group(NotifierProvider, () {
    test('Should correctly build with one dependency', () {
      final container = RefenaContainer();

      final providerA = Provider((ref) => 123);
      final providerB = NotifierProvider<_Notifier, int>((ref) {
        return _Notifier(ref.read(providerA) + 1);
      });

      // Sanity check
      expect(container.read(providerB), 124);

      final notifierA = container.anyNotifier(providerA);
      final notifierB = container.anyNotifier(providerB);

      expect(notifierA.dependencies, isEmpty);
      expect(notifierA.dependents, {notifierB});

      expect(notifierB.dependencies, {notifierA});
      expect(notifierB.dependents, isEmpty);
    });
  });

  group(AsyncNotifierProvider, () {
    test('Should correctly build with one dependency', () async {
      final container = RefenaContainer();

      final providerA = Provider((ref) => 123);
      final providerB = AsyncNotifierProvider<_AsyncNotifier, int>((ref) {
        return _AsyncNotifier(ref.read(providerA) + 1);
      });

      // Sanity check
      expect(await container.future(providerB), 124);

      final notifierA = container.anyNotifier(providerA);
      final notifierB = container.anyNotifier(providerB);

      expect(notifierA.dependencies, isEmpty);
      expect(notifierA.dependents, {notifierB});

      expect(notifierB.dependencies, {notifierA});
      expect(notifierB.dependents, isEmpty);
    });
  });

  group(StateProvider, () {
    test('Should correctly build with one dependency', () {
      final container = RefenaContainer();

      final providerA = Provider((ref) => 123);
      final providerB = StateProvider((ref) => ref.read(providerA) + 1);

      // Sanity check
      expect(container.read(providerB), 124);

      final notifierA = container.anyNotifier(providerA);
      final notifierB = container.anyNotifier(providerB);

      expect(notifierA.dependencies, isEmpty);
      expect(notifierA.dependents, {notifierB});

      expect(notifierB.dependencies, {notifierA});
      expect(notifierB.dependents, isEmpty);
    });
  });

  group(ViewProvider, () {
    test('Should correctly build with one dependency', () {
      final container = RefenaContainer();

      final providerA = Provider((ref) => 123);
      final providerB = ViewProvider((ref) => ref.read(providerA) + 1);

      // Sanity check
      expect(container.read(providerB), 124);

      final notifierA = container.anyNotifier(providerA);
      final notifierB = container.anyNotifier(providerB);

      expect(notifierA.dependencies, isEmpty);
      expect(notifierA.dependents, {notifierB});

      expect(notifierB.dependencies, {notifierA});
      expect(notifierB.dependents, isEmpty);
    });

    test('Should update dependencies after rebuild', () async {
      final container = RefenaContainer();

      final switchProvider = StateProvider((ref) => true);
      final providerA = Provider((ref) => 10);
      final providerB = Provider((ref) => 20);
      final viewProvider = ViewProvider((ref) {
        final b = ref.watch(switchProvider);
        if (b) {
          return ref.watch(providerA) + 1;
        } else {
          return ref.watch(providerB) + 1;
        }
      });

      // Sanity check
      expect(container.read(switchProvider), true);
      expect(container.read(providerA), 10);
      expect(container.read(providerB), 20);
      expect(container.read(viewProvider), 11);

      final switchNotifier = container.anyNotifier(switchProvider);
      final notifierA = container.anyNotifier(providerA);
      final notifierB = container.anyNotifier(providerB);
      final viewNotifier = container.anyNotifier(viewProvider);

      expect(switchNotifier.dependencies, isEmpty);
      expect(switchNotifier.dependents, {viewNotifier});

      expect(notifierA.dependencies, isEmpty);
      expect(notifierA.dependents, {viewNotifier});

      expect(notifierB.dependencies, isEmpty);
      expect(notifierB.dependents, isEmpty);

      expect(viewNotifier.dependencies, {switchNotifier, notifierA});
      expect(viewNotifier.dependents, isEmpty);

      // Change state
      container.notifier(switchProvider).setState((_) => false);
      await skipAllMicrotasks();

      // Sanity check
      expect(container.read(switchProvider), false);
      expect(container.read(providerA), 10);
      expect(container.read(providerB), 20);
      expect(container.read(viewProvider), 21);

      expect(switchNotifier.dependencies, isEmpty);
      expect(switchNotifier.dependents, {viewNotifier});

      expect(notifierA.dependencies, isEmpty);
      expect(notifierA.dependents, isEmpty);

      expect(notifierB.dependencies, isEmpty);
      expect(notifierB.dependents, {viewNotifier});

      expect(viewNotifier.dependencies, {switchNotifier, notifierB});
      expect(viewNotifier.dependents, isEmpty);
    });
  });

  group(ViewFamilyProvider, () {
    test('Should correctly create dependency to temp provider', () async {
      final ref = RefenaContainer();

      final provider = ViewProvider.family<int, int>((ref, param) {
        return param * 2;
      });

      expect(ref.read(provider(5)), 10);

      final viewNotifier = ref.anyNotifier(provider);
      final tempProvider = viewNotifier.getTempProviders().first;
      final tempNotifier = ref.anyNotifier(tempProvider);
      expect(viewNotifier.isParamInitialized(5), true);
      expect(viewNotifier.getTempProviders().length, 1);

      expect(tempNotifier.dependencies, isEmpty);
      expect(tempNotifier.dependents, {viewNotifier});

      expect(viewNotifier.dependencies, {tempNotifier});
      expect(viewNotifier.dependents, isEmpty);
    });

    test('disposeFamilyParam should not dispose family provider', () async {
      final ref = RefenaContainer();

      final provider = ViewProvider.family<int, int>((ref, param) {
        return param * 2;
      });

      expect(ref.read(provider(5)), 10);

      final viewNotifier = ref.anyNotifier(provider);
      final tempProvider = viewNotifier.getTempProviders().first;
      final tempNotifier = ref.anyNotifier(tempProvider);
      expect(viewNotifier.isParamInitialized(5), true);
      expect(viewNotifier.getTempProviders().length, 1);

      expect(tempNotifier.dependencies, isEmpty);
      expect(tempNotifier.dependents, {viewNotifier});

      expect(viewNotifier.dependencies, {tempNotifier});
      expect(viewNotifier.dependents, isEmpty);

      // Dispose param (should not dispose family provider)
      ref.disposeFamilyParam(provider, 5);

      expect(tempNotifier.disposed, true);
      expect(viewNotifier.disposed, false);

      expect(viewNotifier.state, isEmpty);
      expect(viewNotifier.getTempProviders(), isEmpty);

      expect(tempNotifier.dependencies, isEmpty);
      expect(tempNotifier.dependents, isEmpty);

      expect(viewNotifier.dependencies, isEmpty);
      expect(viewNotifier.dependents, isEmpty);
    });

    test('dispose should clear dependency graph', () async {
      final ref = RefenaContainer();

      final provider = ViewProvider.family<int, int>((ref, param) {
        return param * 2;
      });

      expect(ref.read(provider(5)), 10);

      final viewNotifier = ref.anyNotifier(provider);
      final tempProvider = viewNotifier.getTempProviders().first;
      final tempNotifier = ref.anyNotifier(tempProvider);
      expect(viewNotifier.isParamInitialized(5), true);
      expect(viewNotifier.getTempProviders().length, 1);

      expect(tempNotifier.dependencies, isEmpty);
      expect(tempNotifier.dependents, {viewNotifier});

      expect(viewNotifier.dependencies, {tempNotifier});
      expect(viewNotifier.dependents, isEmpty);

      // Dispose param (should not dispose family provider)
      ref.dispose(provider);

      expect(tempNotifier.disposed, true);
      expect(viewNotifier.disposed, true);

      expect(viewNotifier.state, isEmpty);
      expect(viewNotifier.getTempProviders(), isEmpty);

      expect(tempNotifier.dependencies, isEmpty);
      expect(tempNotifier.dependents, isEmpty);

      expect(viewNotifier.dependencies, isEmpty);
      expect(viewNotifier.dependents, isEmpty);
    });
  });

  group(ReduxProvider, () {
    test('Should correctly build with one dependency', () {
      final container = RefenaContainer();

      final providerA = Provider((ref) => 123);
      final providerB = ReduxProvider<_ReduxNotifier, int>((ref) {
        final initial = ref.read(providerA) + 1;
        return _ReduxNotifier(initial);
      });

      // Sanity check
      expect(container.read(providerB), 124);

      final notifierA = container.anyNotifier(providerA);
      final notifierB = container.anyNotifier(providerB);

      expect(notifierA.dependencies, isEmpty);
      expect(notifierA.dependents, {notifierB});

      expect(notifierB.dependencies, {notifierA});
      expect(notifierB.dependents, isEmpty);
    });
  });
}

class _Notifier extends Notifier<int> {
  _Notifier(this._value);

  final int _value;

  @override
  int init() => _value;
}

class _AsyncNotifier extends AsyncNotifier<int> {
  _AsyncNotifier(this._value);

  final int _value;

  @override
  Future<int> init() async => _value;
}

class _ReduxNotifier extends ReduxNotifier<int> {
  _ReduxNotifier(this._value);

  final int _value;

  @override
  int init() => _value;
}
