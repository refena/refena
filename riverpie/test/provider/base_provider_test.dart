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
        'Foo',
      );
    });

    test(FutureProvider, () {
      expect(
        FutureProvider((ref) async => 22).toString(),
        'FutureProvider<int>',
      );

      expect(
        FutureProvider((ref) async => 22, debugLabel: 'Foo').toString(),
        'Foo',
      );
    });

    test(NotifierProvider, () {
      expect(
        NotifierProvider<StateNotifier<int>, int>((ref) => StateNotifier(3))
            .toString(),
        'NotifierProvider<StateNotifier<int>, int>',
      );

      expect(
        NotifierProvider((ref) => StateNotifier(3), debugLabel: 'Foo')
            .toString(),
        'Foo',
      );
    });

    test(AsyncNotifierProvider, () {
      expect(
        AsyncNotifierProvider<FutureProviderNotifier<int>, int>(
          (ref) => FutureProviderNotifier(Future.value(0)),
        ).toString(),
        'AsyncNotifierProvider<FutureProviderNotifier<int>, int>',
      );

      expect(
        AsyncNotifierProvider((ref) => FutureProviderNotifier(Future.value(0)),
                debugLabel: 'Foo')
            .toString(),
        'Foo',
      );
    });

    test(StateProvider, () {
      expect(
        StateProvider<int>((ref) => 11).toString(),
        'StateProvider<int>',
      );

      expect(
        StateProvider<int>((ref) => 11, debugLabel: 'Foo').toString(),
        'Foo',
      );
    });

    test(ViewProvider, () {
      expect(
        ViewProvider<int>((ref) => 11).toString(),
        'ViewProvider<int>',
      );

      expect(
        ViewProvider<int>((ref) => 11, debugLabel: 'Foo').toString(),
        'Foo',
      );
    });
  });
}
