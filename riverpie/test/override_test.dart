import 'dart:async';

import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  group(Provider, () {
    test('Should override', () {
      final provider = Provider((ref) => 123);
      final ref = RiverpieContainer(
        overrides: [
          provider.overrideWithValue((ref) => 456),
        ],
      );

      expect(ref.read(provider), 456);
    });

    test('Should refer to overridden provider', () {
      final providerA = Provider((ref) => 100);
      final providerB = Provider((ref) => ref.read(providerA) + 10);
      final ref = RiverpieContainer(
        overrides: [
          providerA.overrideWithValue((ref) => 200),
          providerB.overrideWithValue((ref) => ref.read(providerA) + 20),
        ],
      );

      expect(ref.read(providerB), 220);
      expect(ref.read(providerA), 200);

      final observer = RiverpieHistoryObserver.all();
      final ref2 = RiverpieContainer(
        observer: observer,
        overrides: [
          providerB.overrideWithValue((ref) => ref.read(providerA) + 40),
          providerA.overrideWithValue((ref) => 400),
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
  });

  group(FutureProvider, () {
    test('Should override', () async {
      final provider = FutureProvider((ref) => Future.value(123));
      final ref = RiverpieContainer(
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
      final ref = RiverpieContainer(
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
      final ref = RiverpieContainer(
        overrides: [
          provider.overrideWithNotifier((ref) => _OverrideAsyncNotifier()),
        ],
      );

      expect(ref.read(provider), AsyncValue<int>.loading());
      expect(await ref.future(provider), 456);
      expect(ref.read(provider), AsyncValue.withData(456));
      expect(ref.notifier(provider).s, 'b');
    });
  });

  group(StateProvider, () {
    test('Should override', () {
      final provider = StateProvider((ref) => 123);
      final ref = RiverpieContainer(
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
      final ref = RiverpieContainer(
        overrides: [
          provider.overrideWithBuilder((ref) => 456),
        ],
      );

      expect(ref.read(provider), 456);
    });
  });

  group(ReduxNotifier, () {
    test('Should override with notifier', () {
      final provider = NotifierProvider((ref) => _ReduxNotifier());
      final ref = RiverpieContainer(
        overrides: [
          provider.overrideWithNotifier((ref) => _OverrideReduxNotifier()),
        ],
      );

      expect(ref.read(provider), 456);

      ref.notifier(provider).emit(_Event.inc);

      expect(ref.read(provider), 458);
    });

    test('Should override with enum reducer', () {
      final provider =
          NotifierProvider<_ReduxNotifier, int>((ref) => _ReduxNotifier());
      final ref = RiverpieContainer(
        overrides: [
          provider.overrideWithReducer(
            notifier: (ref) => _ReduxNotifier(),
            overrides: {
              _Event.inc: (state, event) => state + 21,
              _Event.dec: null,
            },
          ),
        ],
      );

      expect(ref.read(provider), 123);

      // Should use the overridden reducer
      ref.notifier(provider).emit(_Event.inc);
      expect(ref.read(provider), 144);

      // Should not change the state
      ref.notifier(provider).emit(_Event.dec);
      expect(ref.read(provider), 144);

      // Should not be overridden
      ref.notifier(provider).emit(_Event.half);
      expect(ref.read(provider), 72);
    });

    test('Should override with class reducer', () {
      final provider = NotifierProvider<_Counter, int>((ref) => _Counter());
      final ref = RiverpieContainer(
        overrides: [
          provider.overrideWithReducer(
            overrides: {
              _AddEvent: (state, event) => state + 21,
              _SubtractEvent: null,
            },
          ),
        ],
      );

      expect(ref.read(provider), 123);

      // Should use the overridden reducer
      ref.notifier(provider).emit(_AddEvent());
      expect(ref.read(provider), 144);

      // Should not change the state
      ref.notifier(provider).emit(_SubtractEvent());
      expect(ref.read(provider), 144);
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
  Future<int> init() => Future.value(456);

  @override
  String get s => 'b';
}

enum _Event { inc, dec, half }

class _ReduxNotifier extends ReduxNotifier<int, _Event> {
  @override
  int init() => 123;

  @override
  int reduce(_Event event) {
    return switch (event) {
      _Event.inc => state + 1,
      _Event.dec => state - 1,
      _Event.half => state ~/ 2,
    };
  }
}

class _OverrideReduxNotifier extends _ReduxNotifier {
  @override
  int init() => 456;

  @override
  int reduce(_Event event) {
    return switch (event) {
      _Event.inc => state + 2,
      _Event.dec => state - 2,
      _Event.half => state ~/ 4,
    };
  }
}

sealed class _CountEvent {}

class _AddEvent extends _CountEvent {}

class _SubtractEvent extends _CountEvent {}

class _Counter extends ReduxNotifier<int, _CountEvent> {
  @override
  int init() => 123;

  @override
  int reduce(_CountEvent event) {
    return switch (event) {
      _AddEvent() => state + 1,
      _SubtractEvent() => state - 1,
    };
  }
}
