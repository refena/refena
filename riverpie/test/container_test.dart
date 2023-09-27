import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

import 'util/skip_microtasks.dart';

void main() {
  group('read', () {
    late RiverpieHistoryObserver observer;

    setUp(() {
      observer = RiverpieHistoryObserver.only(
        providerInit: true,
      );
    });

    test('Should initialize provider lazily', () {
      final ref = RiverpieContainer(
        observer: observer,
      );
      final stateProvider = StateProvider((ref) => 10);

      expect(observer.history, isEmpty);
      expect(ref.read(stateProvider), 10);
      expect(ref.anyNotifier(stateProvider).provider, stateProvider);
      expect(observer.history, [isA<ProviderInitEvent>()]);
    });
  });

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

    test('Disposing a ViewProvider should dispose the listener', () async {
      observer = RiverpieHistoryObserver.only(
        providerInit: true,
        providerDispose: true,
        change: true,
        rebuild: true,
      );

      final ref = RiverpieContainer(observer: observer);
      final stateProvider = StateProvider((ref) => 10);
      final viewProvider = ViewProvider<int>((ref) {
        return ref.watch(stateProvider);
      });

      expect(ref.read(viewProvider), 10);

      ref.notifier(stateProvider).setState((old) => old + 1);

      await skipAllMicrotasks();

      expect(ref.read(viewProvider), 11);

      ref.dispose(viewProvider);

      // This should not trigger a rebuild of the disposed view provider
      ref.notifier(stateProvider).setState((old) => old + 1);

      // Here it should be reinitialized again
      expect(ref.read(viewProvider), 12);

      ref.notifier(stateProvider).setState((old) => old + 1);

      await skipAllMicrotasks();

      // Back to normal: Rebuilds are triggered again
      expect(ref.read(viewProvider), 13);

      expect(
        observer.history,
        [
          isA<ProviderInitEvent>(),
          isA<ProviderInitEvent>(),
          isA<ChangeEvent>(),
          isA<RebuildEvent>(),
          isA<ProviderDisposeEvent>(),
          isA<ChangeEvent>(),
          isA<ProviderInitEvent>(),
          isA<ChangeEvent>(),
          isA<RebuildEvent>(),
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
