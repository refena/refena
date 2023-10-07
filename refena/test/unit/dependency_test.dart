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

      final providerA = StateProvider((ref) => 123);
      final providerB = Provider((ref) => 10);
      final providerC = Provider((ref) => 20);
      final providerD = ViewProvider((ref) {
        final a = ref.watch(providerA);
        if (a == 123) {
          return ref.watch(providerB) + 1;
        } else {
          return ref.watch(providerC) + 1;
        }
      });

      // Sanity check
      expect(container.read(providerA), 123);
      expect(container.read(providerB), 10);
      expect(container.read(providerC), 20);
      expect(container.read(providerD), 11);

      final notifierA = container.anyNotifier(providerA);
      final notifierB = container.anyNotifier(providerB);
      final notifierC = container.anyNotifier(providerC);
      final notifierD = container.anyNotifier(providerD);

      expect(notifierA.dependencies, isEmpty);
      expect(notifierA.dependents, {notifierD});

      expect(notifierB.dependencies, isEmpty);
      expect(notifierB.dependents, {notifierD});

      expect(notifierC.dependencies, isEmpty);
      expect(notifierC.dependents, isEmpty);

      expect(notifierD.dependencies, {notifierA, notifierB});
      expect(notifierD.dependents, isEmpty);

      // Change state
      container.notifier(providerA).setState((old) => old + 1);
      await skipAllMicrotasks();

      // Sanity check
      expect(container.read(providerA), 124);
      expect(container.read(providerB), 10);
      expect(container.read(providerC), 20);
      expect(container.read(providerD), 21);

      expect(notifierA.dependencies, isEmpty);
      expect(notifierA.dependents, {notifierD});

      expect(notifierB.dependencies, isEmpty);
      expect(notifierB.dependents, isEmpty);

      expect(notifierC.dependencies, isEmpty);
      expect(notifierC.dependents, {notifierD});

      expect(notifierD.dependencies, {notifierA, notifierC});
      expect(notifierD.dependents, isEmpty);
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
