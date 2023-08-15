import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpie/riverpie.dart';

void main() {
  group(Provider, () {
    test('Should override', () {
      final provider = Provider((ref) => 123);
      final scope = RiverpieScope(
        overrides: [
          provider.overrideWithValue(456),
        ],
        child: Container(),
      );

      expect(scope.read(provider), 456);
    });
  });

  group(FutureProvider, () {
    test('Should override', () async {
      final provider = FutureProvider((ref) => Future.value(123));
      final scope = RiverpieScope(
        overrides: [
          provider.overrideWithFuture(Future.value(456)),
        ],
        child: Container(),
      );

      expect(await scope.future(provider), 456);
    });
  });

  group(NotifierProvider, () {
    test('Should override', () {
      final provider = NotifierProvider((ref) => _Notifier());
      final scope = RiverpieScope(
        overrides: [
          provider.overrideWithNotifier(() => _OverrideNotifier()),
        ],
        child: Container(),
      );

      expect(scope.read(provider), 456);
    });
  });

  group(AsyncNotifierProvider, () {
    test('Should override', () async {
      final provider = AsyncNotifierProvider((ref) => _AsyncNotifier());
      final scope = RiverpieScope(
        overrides: [
          provider.overrideWithNotifier(() => _OverrideAsyncNotifier()),
        ],
        child: Container(),
      );

      expect(scope.read(provider), AsyncSnapshot<int>.waiting());
      expect(await scope.future(provider), 456);
      expect(
        scope.read(provider),
        AsyncSnapshot.withData(
          ConnectionState.done,
          456,
        ),
      );
    });
  });

  group(StateProvider, () {
    test('Should override', () {
      final provider = StateProvider((ref) => 123);
      final scope = RiverpieScope(
        overrides: [
          provider.overrideWithInitialState(456),
        ],
        child: Container(),
      );

      expect(scope.read(provider), 456);
    });
  });

  group(ViewProvider, () {
    test('Should override', () {
      final provider = ViewProvider((ref) => 123);
      final scope = RiverpieScope(
        overrides: [
          provider.overrideWithBuilder((ref) => 456),
        ],
        child: Container(),
      );

      expect(scope.read(provider), 456);
    });
  });
}

class _Notifier extends Notifier<int> {
  @override
  int init() => 123;
}

class _OverrideNotifier extends _Notifier {
  @override
  int init() => 456;
}

class _AsyncNotifier extends AsyncNotifier<int> {
  @override
  Future<int> init() => Future.value(123);
}

class _OverrideAsyncNotifier extends _AsyncNotifier {
  @override
  Future<int> init() => Future.value(456);
}
