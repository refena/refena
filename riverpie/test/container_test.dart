import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  group('dispose', () {
    late RiverpieHistoryObserver observer;

    setUp(() {
      observer = RiverpieHistoryObserver.only(
        providerInit: true,
        providerDispose: true,
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

    test('Provider should be alive during onDispose hook', () {
      final ref = RiverpieContainer(observer: observer);
      int? stateDuringDispose;
      final notifierProvider = NotifierProvider<_DisposableNotifier, int>(
        (ref) => _DisposableNotifier(),
      );
      ref.notifier(notifierProvider).onDispose = () {
        stateDuringDispose = ref.read(notifierProvider);
      };

      expect(ref.read(notifierProvider), 20);

      ref.notifier(notifierProvider).doubleIt();
      expect(ref.read(notifierProvider), 40);

      ref.dispose(notifierProvider);
      expect(ref.read(notifierProvider), 20);
      expect(stateDuringDispose, 40);

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
      observer = RiverpieHistoryObserver.only(
        message: true,
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

class _DisposableNotifier extends Notifier<int> {
  void Function()? onDispose;

  @override
  int init() => 20;

  void doubleIt() {
    state *= 2;
  }

  @override
  void dispose() {
    onDispose?.call();
    super.dispose();
  }
}
