import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  group('toString', () {
    test(Provider, () {
      expect(
        Provider((ref) => 11).toString(),
        'Provider<int>',
      );

      expect(
        Provider((ref) => 11, debugLabel: 'Foo').toString(),
        'Provider<int>(label: Foo)',
      );
    });

    test(FutureProvider, () {
      expect(
        FutureProvider((ref) async => 22).toString(),
        'FutureProvider<int>',
      );

      expect(
        FutureProvider((ref) async => 22, debugLabel: 'Foo').toString(),
        'FutureProvider<int>(label: Foo)',
      );
    });

    test(NotifierProvider, () {
      expect(
        NotifierProvider<_MyNotifier, int>((ref) => _MyNotifier()).toString(),
        'NotifierProvider<_MyNotifier, int>(label: _MyNotifier)',
      );

      expect(
        NotifierProvider<_MyNotifier, int>(
          (ref) => _MyNotifier(),
          debugLabel: 'Foo',
        ).toString(),
        'NotifierProvider<_MyNotifier, int>(label: Foo)',
      );
    });

    test(AsyncNotifierProvider, () {
      expect(
        AsyncNotifierProvider<FutureProviderNotifier<int>, int>(
          (ref) => FutureProviderNotifier(Future.value(0)),
        ).toString(),
        'AsyncNotifierProvider<FutureProviderNotifier<int>, int>(label: FutureProviderNotifier<int>)',
      );

      expect(
        AsyncNotifierProvider<FutureProviderNotifier<int>, int>(
          (ref) => FutureProviderNotifier(Future.value(0)),
          debugLabel: 'Foo',
        ).toString(),
        'AsyncNotifierProvider<FutureProviderNotifier<int>, int>(label: Foo)',
      );
    });

    test(StateProvider, () {
      expect(
        StateProvider<int>((ref) => 11).toString(),
        'StateProvider<int>',
      );

      expect(
        StateProvider<int>((ref) => 11, debugLabel: 'Foo').toString(),
        'StateProvider<int>(label: Foo)',
      );
    });

    test(ViewProvider, () {
      expect(
        ViewProvider<int>((ref) => 11).toString(),
        'ViewProvider<int>',
      );

      expect(
        ViewProvider<int>((ref) => 11, debugLabel: 'Foo').toString(),
        'ViewProvider<int>(label: Foo)',
      );
    });
  });
}

class _MyNotifier extends Notifier<int> {
  @override
  int init() => 0;
}
