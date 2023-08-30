import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  late RiverpieHistoryObserver observer;

  setUp(() {
    observer = RiverpieHistoryObserver(
      HistoryObserverConfig.only(
        providerInitEvents: true,
        providerDisposeEvents: true,
      ),
    );
  });

  group('dispose', () {
    test('Should dispose a provider', () {
      final ref = RiverpieContainer(observer: observer);
      final stateProvider = StateProvider((ref) => 10);

      expect(ref.read(stateProvider), 10);

      ref.notifier(stateProvider).setState((old) => old + 1);

      expect(ref.read(stateProvider), 11);

      ref.dispose(stateProvider);

      expect(ref.read(stateProvider), 10);

      expect(
        observer.history,
        [
          isA<ProviderInitEvent>(),
          isA<ProviderDisposeEvent>(),
          isA<ProviderInitEvent>(),
        ],
      );
    });

    test('Should ignore calling dispose multiple times', () {
      final ref = RiverpieContainer(observer: observer);
      final stateProvider = StateProvider((ref) => 10);

      expect(ref.read(stateProvider), 10);

      ref.notifier(stateProvider).setState((old) => old + 1);

      expect(ref.read(stateProvider), 11);

      ref.dispose(stateProvider);
      ref.dispose(stateProvider);

      expect(ref.read(stateProvider), 10);

      expect(
        observer.history,
        [
          isA<ProviderInitEvent>(),
          isA<ProviderDisposeEvent>(),
          isA<ProviderInitEvent>(),
        ],
      );
    });
  });
}
