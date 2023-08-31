import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  group('dispose', () {
    late RiverpieHistoryObserver observer;

    setUp(() {
      observer = RiverpieHistoryObserver(
        HistoryObserverConfig.only(
          providerInitEvents: true,
          providerDisposeEvents: true,
        ),
      );
    });

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

  group('emitMessage', () {
    late RiverpieHistoryObserver observer;

    setUp(() {
      observer = RiverpieHistoryObserver(
        HistoryObserverConfig.only(
          messageEvents: true,
        ),
      );
    });

    test('Should emit a message', () {
      final ref = RiverpieContainer(observer: observer);

      ref.message('Hello world!!');

      expect(observer.history.length, 1);

      final event = observer.history.first as MessageEvent;
      expect(event.message, 'Hello world!!');
      expect(event.origin, ref);
    });
  });
}
