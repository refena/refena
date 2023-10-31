import 'dart:async';

import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../util/skip_microtasks.dart';

void main() {
  group('ensureOverrides', () {
    test('Should return immediately if no overrides are specified', () async {
      final ref = RefenaContainer();
      int? delayedValue;
      Future.delayed(Duration.zero, () {
        delayedValue = 10;
      });
      await ref.ensureOverrides();

      // The next microtask should not be executed yet.
      // Therefore, ensureOverrides finished before the delayedValue is set.
      expect(delayedValue, null);

      await skipAllMicrotasks();

      expect(delayedValue, 10);
    });

    // For more tests, see Provider group.
  });

  group('setOverride', () {
    test('Should override', () {
      final ref = RefenaContainer();
      final provider = Provider((ref) => 123);

      expect(ref.read(provider), 123);

      ref.set(
        provider.overrideWithValue(456),
      );

      expect(ref.read(provider), 456);
    });
  });

  group(Provider, () {
    test('Should override with plain value', () {
      final provider = Provider((ref) => 123);
      final ref = RefenaContainer(
        overrides: [
          provider.overrideWithValue(500),
        ],
      );

      expect(ref.read(provider), 500);
    });

    test('Should override with builder', () {
      final provider = Provider((ref) => 123);
      final ref = RefenaContainer(
        overrides: [
          provider.overrideWithBuilder((ref) => 456),
        ],
      );

      expect(ref.read(provider), 456);
    });

    test('Should refer to overridden provider', () {
      final providerA = Provider((ref) => 100);
      final providerB = Provider((ref) => ref.read(providerA) + 10);
      final ref = RefenaContainer(
        overrides: [
          providerA.overrideWithValue(200),
          providerB.overrideWithBuilder((ref) => ref.read(providerA) + 20),
        ],
      );

      expect(ref.read(providerB), 220);
      expect(ref.read(providerA), 200);

      // different order
      final observer = RefenaHistoryObserver.all();
      final ref2 = RefenaContainer(
        observers: [observer],
        overrides: [
          providerB.overrideWithBuilder((ref) => ref.read(providerA) + 40),
          providerA.overrideWithValue(400),
        ],
      );

      expect(ref2.read(providerB), 440);
      expect(ref2.read(providerA), 400);

      // Check events
      expect(observer.history, [
        ProviderInitEvent(
          provider: providerA,
          notifier: ref2.anyNotifier<ImmutableNotifier<int>, int>(providerA),
          cause: ProviderInitCause.override,
          value: 400,
        ),
        ProviderInitEvent(
          provider: providerB,
          notifier: ref2.anyNotifier<ImmutableNotifier<int>, int>(providerB),
          cause: ProviderInitCause.override,
          value: 440,
        ),
      ]);
    });

    test('Should refer to non-overridden provider', () {
      final providerA = Provider((ref) => 100);
      final providerB = Provider((ref) => ref.read(providerA) + 10);
      final observer = RefenaHistoryObserver.all();
      final ref = RefenaContainer(
        observers: [observer],
        overrides: [
          providerB.overrideWithBuilder((ref) => ref.read(providerA) + 200),
        ],
      );

      expect(ref.read(providerB), 300);
      expect(ref.read(providerA), 100);

      // Check events
      expect(observer.history, [
        ProviderInitEvent(
          provider: providerA,
          notifier: ref.anyNotifier<ImmutableNotifier<int>, int>(providerA),
          cause: ProviderInitCause.access,
          value: 100,
        ),
        ProviderInitEvent(
          provider: providerB,
          notifier: ref.anyNotifier<ImmutableNotifier<int>, int>(providerB),
          cause: ProviderInitCause.override,
          value: 300,
        ),
      ]);
    });

    test('Should await async override', () async {
      final providerA = FutureProvider((ref) async {
        await Future.delayed(Duration(milliseconds: 50));
        return 100;
      });
      final providerB = Provider<int>((ref) => throw 'Not initialized');
      final ref = RefenaContainer(
        overrides: [
          providerB.overrideWithFuture((ref) async {
            return await ref.future(providerA) + 200;
          }),
        ],
      );

      expect(
        () => ref.read(providerB),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Future override not yet initialized. Call await RefenaContainer.ensureOverrides() first.',
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      await ref.ensureOverrides();
      await ref.ensureOverrides(); // Should be safe to call multiple times

      // >= 100 may infer that the future is awaited twice
      expect(stopwatch.elapsedMilliseconds, lessThan(99));

      expect(ref.read(providerB), 300);
      expect(await ref.future(providerA), 100);
    });

    test('Should await multiple async overrides', () async {
      final providerA = Provider<int>((ref) => throw 'Not initialized');
      final providerB = Provider<int>((ref) => throw 'Not initialized');
      final ref = RefenaContainer(
        overrides: [
          // order is important
          providerA.overrideWithFuture((ref) async {
            await Future.delayed(Duration(milliseconds: 50));
            return 100;
          }),
          providerB.overrideWithBuilder((ref) {
            return ref.read(providerA) + 200;
          }),
        ],
      );

      expect(
        () => ref.read(providerA),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Future override not yet initialized. Call await RefenaContainer.ensureOverrides() first.',
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      await ref.ensureOverrides();
      await ref.ensureOverrides(); // Should be safe to call multiple times

      // >= 100 may infer that the future is awaited twice
      expect(stopwatch.elapsedMilliseconds, lessThan(99));

      expect(ref.read(providerB), 300);
      expect(ref.read(providerA), 100);
    });

    test('Should throw error on wrong order of async overrides', () async {
      final providerA = Provider<int>(
        (ref) => throw 'Not initialized',
        debugLabel: 'Provider A',
      );
      final providerB = Provider<int>(
        (ref) => throw 'Not initialized',
        debugLabel: 'Provider B',
      );
      init() => RefenaContainer(
            overrides: [
              providerB.overrideWithBuilder((ref) {
                return ref.read(providerA) + 200;
              }),
              providerA.overrideWithFuture((ref) async {
                await Future.delayed(Duration(milliseconds: 50));
                return 100;
              }),
            ],
          );

      await expectLater(
        () async {
          final ref = init();
          await ref.ensureOverrides();
        },
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            '[Provider B] depends on [Provider A] which is overridden later. Reorder future overrides.',
          ),
        ),
      );
    });
  });

  group(FutureProvider, () {
    test('Should override', () async {
      final provider = FutureProvider((ref) => Future.value(123));
      final ref = RefenaContainer(
        overrides: [
          provider.overrideWithFuture((ref) => Future.value(456)),
        ],
      );

      expect(await ref.future(provider), 456);
    });
  });

  group(NotifierProvider, () {
    test('Should override', () {
      final provider = NotifierProvider((ref) => _Notifier());
      final ref = RefenaContainer(
        overrides: [
          provider.overrideWithNotifier((ref) => _OverrideNotifier()),
        ],
      );

      expect(ref.read(provider), 456);
      expect(ref.notifier(provider).s, 'b');
    });
  });

  group(AsyncNotifierProvider, () {
    test('Should override', () async {
      final provider = AsyncNotifierProvider((ref) => _AsyncNotifier());
      final ref = RefenaContainer(
        overrides: [
          provider.overrideWithNotifier((ref) => _OverrideAsyncNotifier()),
        ],
      );

      expect(ref.read(provider), AsyncValue<int>.loading());
      expect(await ref.future(provider), 456);
      expect(ref.read(provider), AsyncValue.data(456));
      expect(ref.notifier(provider).s, 'b');
    });
  });

  group(StateProvider, () {
    test('Should override', () {
      final provider = StateProvider((ref) => 123);
      final ref = RefenaContainer(
        overrides: [
          provider.overrideWithInitialState((ref) => 456),
        ],
      );

      expect(ref.read(provider), 456);
    });
  });

  group(ViewProvider, () {
    test('Should override', () {
      final provider = ViewProvider((ref) => 123);
      final ref = RefenaContainer(
        overrides: [
          provider.overrideWithBuilder((ref) => 456),
        ],
      );

      expect(ref.read(provider), 456);
    });
  });

  group(ReduxNotifier, () {
    test('Should override with notifier', () {
      final provider =
          ReduxProvider<_ReduxNotifier, int>((ref) => _ReduxNotifier());
      final ref = RefenaContainer(
        overrides: [
          provider.overrideWithNotifier((ref) => _OverrideReduxNotifier()),
        ],
      );

      expect(ref.read(provider), 456);

      ref.redux(provider).dispatch(_IncAction());

      expect(ref.read(provider), 457);
    });

    test('Should override with reducer', () {
      final provider =
          ReduxProvider<_ReduxNotifier, int>((ref) => _ReduxNotifier());
      final ref = RefenaContainer(
        overrides: [
          provider.overrideWithReducer(
            notifier: (ref) => _ReduxNotifier(),
            reducer: {
              _IncAction: (state) => state + 21,
              _DecAction: null,
            },
          ),
        ],
      );

      expect(ref.read(provider), 123);

      // Should use the overridden reducer
      ref.redux(provider).dispatch(_IncAction());
      expect(ref.read(provider), 144);

      // Should not change the state
      ref.redux(provider).dispatch(_DecAction());
      expect(ref.read(provider), 144);

      // Should not be overridden
      // ignore: invalid_use_of_protected_member
      ref.anyNotifier(provider).dispatch(_HalfAction());
      expect(ref.read(provider), 72);
    });

    test('Should override with initial state', () {
      final provider1 =
          ReduxProvider<_ReduxNotifier, int>((ref) => _ReduxNotifier());
      final provider2 =
          ReduxProvider<_ReduxNotifier, int>((ref) => _ReduxNotifier());
      final ref = RefenaContainer(
        overrides: [
          provider1.overrideWithInitialState(
            initialState: 555,
          ),
          provider2.overrideWithReducer(
            initialState: 666,
            reducer: {},
          ),
        ],
      );

      expect(ref.read(provider1), 555);
      expect(ref.read(provider2), 666);
    });

    test('Should override global reducer', () {
      final observer = RefenaHistoryObserver.only(
        actionDispatched: true,
        message: true,
      );
      final ref = RefenaContainer(
        observers: [observer],
        overrides: [
          globalReduxProvider.overrideWithGlobalReducer(
            reducer: {
              _GlobalAction1: (ref) => ref.message('overridden!'),
              _GlobalAction2: null,
            },
          ),
        ],
      );

      // Should use the overridden reducer
      ref.dispatch(_GlobalAction1());

      // Should do nothing
      ref.dispatch(_GlobalAction2());

      // Should not be overridden
      ref.dispatch(_GlobalAction3());

      expect(observer.history.length, 5);

      expect(observer.history[0], isA<ActionDispatchedEvent>());
      expect((observer.history[0] as ActionDispatchedEvent).action,
          isA<_GlobalAction1>());

      expect(observer.history[1], isA<MessageEvent>());
      expect((observer.history[1] as MessageEvent).message, 'overridden!');

      expect(observer.history[2], isA<ActionDispatchedEvent>());
      expect((observer.history[2] as ActionDispatchedEvent).action,
          isA<_GlobalAction2>());

      expect(observer.history[3], isA<ActionDispatchedEvent>());
      expect((observer.history[3] as ActionDispatchedEvent).action,
          isA<_GlobalAction3>());

      expect(observer.history[4], isA<MessageEvent>());
      expect((observer.history[4] as MessageEvent).message, 'original 3');
    });
  });
}

class _Notifier extends Notifier<int> {
  @override
  int init() => 123;

  String get s => 'a';
}

class _OverrideNotifier extends _Notifier {
  @override
  int init() => 456;

  @override
  String get s => 'b';
}

class _AsyncNotifier extends AsyncNotifier<int> {
  @override
  Future<int> init() => Future.value(123);

  String get s => 'a';
}

class _OverrideAsyncNotifier extends _AsyncNotifier {
  @override
  Future<int> init() async {
    await Future.delayed(Duration(milliseconds: 50));
    return Future.value(456);
  }

  @override
  String get s => 'b';
}

class _ReduxNotifier extends ReduxNotifier<int> {
  @override
  int init() => 123;
}

class _IncAction extends ReduxAction<_ReduxNotifier, int> {
  @override
  int reduce() {
    return state + 1;
  }
}

class _DecAction extends ReduxAction<_ReduxNotifier, int> {
  @override
  int reduce() {
    return state - 1;
  }
}

class _HalfAction extends ReduxAction<_ReduxNotifier, int> {
  @override
  int reduce() {
    return state ~/ 2;
  }
}

class _OverrideReduxNotifier extends _ReduxNotifier {
  @override
  int init() => 456;
}

class _GlobalAction1 extends GlobalAction {
  @override
  void reduce() {
    ref.message('original 1');
  }
}

class _GlobalAction2 extends GlobalAction {
  @override
  void reduce() {
    ref.message('original 2');
  }
}

class _GlobalAction3 extends GlobalAction {
  @override
  void reduce() {
    ref.message('original 3');
  }
}
