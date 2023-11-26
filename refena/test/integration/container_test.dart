import 'package:refena/refena.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:test/test.dart';

import '../util/skip_microtasks.dart';

void main() {
  group('defaultNotifyStrategy', () {
    test('Should rebuild on identity change', () async {
      final stateProvider = StateProvider((ref) => _DummyClass(0));
      final observer = RefenaHistoryObserver.all();
      final ref = RefenaContainer(
        observers: [observer],
        defaultNotifyStrategy: NotifyStrategy.identity,
      );

      ref.read(stateProvider);
      ref.notifier(stateProvider).setState((old) => _DummyClass(0));

      await skipAllMicrotasks();
      expect(observer.history, [
        isA<ProviderInitEvent>(),
        isA<ChangeEvent>(),
      ]);
    });

    test('Should rebuild on equality change', () async {
      final stateProvider = StateProvider((ref) => _DummyClass(0));
      final observer = RefenaHistoryObserver.all();
      final ref = RefenaContainer(
        observers: [observer],
        defaultNotifyStrategy: NotifyStrategy.equality,
      );

      ref.read(stateProvider);

      ref.notifier(stateProvider).setState((old) => _DummyClass(0));

      await skipAllMicrotasks();
      expect(observer.history, [
        isA<ProviderInitEvent>(),
      ]);

      ref.notifier(stateProvider).setState((old) => _DummyClass(1));

      await skipAllMicrotasks();
      expect(observer.history, [
        isA<ProviderInitEvent>(),
        isA<ChangeEvent>(),
      ]);
    });
  });

  group('read', () {
    late RefenaHistoryObserver observer;

    setUp(() {
      observer = RefenaHistoryObserver.only(
        providerInit: true,
      );
    });

    test('Should initialize provider lazily', () {
      final ref = RefenaContainer(
        observers: [observer],
      );
      final stateProvider = StateProvider((ref) => 10);

      expect(observer.history, isEmpty);
      expect(ref.read(stateProvider), 10);
      expect(ref.anyNotifier(stateProvider).provider, stateProvider);
      expect(observer.history, [isA<ProviderInitEvent>()]);
    });
  });

  group('dispose', () {
    late RefenaHistoryObserver observer;

    setUp(() {
      observer = RefenaHistoryObserver.only(
        providerInit: true,
        providerDispose: true,
      );
    });

    test('Should dispose a provider', () {
      final ref = RefenaContainer(observers: [observer]);
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
      observer = RefenaHistoryObserver.only(
        providerInit: true,
        providerDispose: true,
        change: true,
        rebuild: true,
      );

      final ref = RefenaContainer(observers: [observer]);
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
      final ref = RefenaContainer(observers: [observer]);
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
      final ref = RefenaContainer(observers: [observer]);
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

    test('Should dispose dependent providers', () async {
      final ref = RefenaContainer(observers: [observer]);
      final stateProvider = StateProvider((ref) => 10);
      final c1Provider = ViewProvider((ref) {
        return ref.watch(stateProvider);
      });
      final c2Provider = ViewProvider((ref) {
        return ref.watch(stateProvider);
      });
      final c3Provider = ViewProvider((ref) {
        return ref.watch(c1Provider) + ref.watch(c2Provider);
      });
      final c4Provider = ViewProvider((ref) {
        return ref.watch(c3Provider);
      });

      expect(ref.read(stateProvider), 10);
      expect(ref.read(c1Provider), 10);
      expect(ref.read(c2Provider), 10);
      expect(ref.read(c3Provider), 20);
      expect(ref.read(c4Provider), 20);

      ref.notifier(stateProvider).setState((old) => old + 1);
      await skipAllMicrotasks();

      expect(ref.read(stateProvider), 11);
      expect(ref.read(c1Provider), 11);
      expect(ref.read(c2Provider), 11);
      expect(ref.read(c3Provider), 22);
      expect(ref.read(c4Provider), 22);

      ref.dispose(stateProvider);

      expect(
        observer.history,
        [
          isA<ProviderInitEvent>(),
          isA<ProviderInitEvent>(),
          isA<ProviderInitEvent>(),
          isA<ProviderInitEvent>(),
          isA<ProviderInitEvent>(),
          isA<ProviderDisposeEvent>(),
          isA<ProviderDisposeEvent>(),
          isA<ProviderDisposeEvent>(),
          isA<ProviderDisposeEvent>(),
          isA<ProviderDisposeEvent>(),
        ],
      );
      expect(
        (observer.history[5] as ProviderDisposeEvent).provider,
        stateProvider,
      );
      expect(
        (observer.history[6] as ProviderDisposeEvent).provider,
        c1Provider,
      );
      expect(
        (observer.history[7] as ProviderDisposeEvent).provider,
        c2Provider,
      );
      expect(
        (observer.history[8] as ProviderDisposeEvent).provider,
        c3Provider,
      );
      expect(
        (observer.history[9] as ProviderDisposeEvent).provider,
        c4Provider,
      );
      expect((observer.history[5] as ProviderDisposeEvent).debugOrigin, ref);
      expect(
        (observer.history[6] as ProviderDisposeEvent).debugOrigin,
        observer.history[5],
      );
      expect(
        (observer.history[7] as ProviderDisposeEvent).debugOrigin,
        observer.history[5],
      );
      expect(
        (observer.history[8] as ProviderDisposeEvent).debugOrigin,
        observer.history[6],
      );
      expect(
        (observer.history[9] as ProviderDisposeEvent).debugOrigin,
        observer.history[8],
      );
    });

    test('Should dispose whole family', () async {
      final ref = RefenaContainer(observers: [observer]);
      final viewProvider = ViewFamilyProvider<String, int>((ref, param) {
        return '$param';
      });

      expect(ref.read(viewProvider(10)), '10');
      expect(ref.read(viewProvider(20)), '20');

      final familyNotifier = ref.anyNotifier(viewProvider);
      final tempProvider10 = familyNotifier.getTempProviders().first;
      final tempProvider20 = familyNotifier.getTempProviders().last;

      expect(ref.getActiveProviders(), hasLength(3));
      expect(ref.getActiveProviders(), {
        viewProvider,
        tempProvider10,
        tempProvider20,
      });

      ref.dispose(viewProvider);

      expect(ref.getActiveProviders(), isEmpty);
      expect(
        observer.history,
        [
          isA<ProviderInitEvent>()
              .having((e) => e.provider, 'provider', viewProvider),
          isA<ProviderInitEvent>()
              .having((e) => e.provider, 'provider', tempProvider10),
          isA<ProviderInitEvent>()
              .having((e) => e.provider, 'provider', tempProvider20),
          isA<ProviderDisposeEvent>()
              .having((e) => e.provider, 'provider', viewProvider)
              .having((e) => e.debugOrigin, 'debugOrigin', ref),
          isA<ProviderDisposeEvent>()
              .having((e) => e.provider, 'provider', tempProvider10)
              .having(
                (e) => e.debugOrigin,
                'debugOrigin',
                ProviderDisposeEvent(debugOrigin: ref, provider: viewProvider),
              ),
          isA<ProviderDisposeEvent>()
              .having((e) => e.provider, 'provider', tempProvider20)
              .having(
                (e) => e.debugOrigin,
                'debugOrigin',
                ProviderDisposeEvent(debugOrigin: ref, provider: viewProvider),
              ),
        ],
      );
    });
  });

  group('emitMessage', () {
    late RefenaHistoryObserver observer;

    setUp(() {
      observer = RefenaHistoryObserver.only(
        message: true,
      );
    });

    test('Should emit a message', () {
      final ref = RefenaContainer(observers: [observer]);

      ref.message('Hello world!!');

      expect(observer.history.length, 1);

      final event = observer.history.first as MessageEvent;
      expect(event.message, 'Hello world!!');
      expect(event.origin, ref);
    });
  });

  group('disposeContainer', () {
    test('Should dispose all providers', () {
      final ref = RefenaContainer();
      bool disposedCalledA = false;
      final notifierProviderA = NotifierProvider<_DisposableNotifier, int>(
        (ref) => _DisposableNotifier(),
      );
      ref.notifier(notifierProviderA).onDispose = () {
        disposedCalledA = true;
      };

      bool disposedCalledB = false;
      final notifierProviderB = NotifierProvider<_DisposableNotifier, int>(
        (ref) => _DisposableNotifier(),
      );
      ref.notifier(notifierProviderB).onDispose = () {
        disposedCalledB = true;
      };

      expect(ref.read(notifierProviderA), 20);
      expect(ref.read(notifierProviderB), 20);

      ref.disposeContainer();

      expect(ref.disposed, true);
      expect(disposedCalledA, true);
      expect(disposedCalledB, true);
    });

    test('Should dispose all observers', () {
      final observerA = _DisposableObserver();
      final observerB = _DisposableObserver();
      final ref = RefenaContainer(
        observers: [observerA, observerB],
      );

      expect(observerA._disposed, false);
      expect(observerB._disposed, false);

      ref.disposeContainer();

      expect(ref.disposed, true);
      expect(observerA._disposed, true);
      expect(observerB._disposed, true);
    });
  });

  group('exists', () {
    test('Should return correct exists state', () {
      final ref = RefenaContainer();
      final stateProvider = StateProvider((ref) => 10);

      expect(ref.exists(stateProvider), false);

      ref.read(stateProvider);
      expect(ref.exists(stateProvider), true);

      ref.dispose(stateProvider);
      expect(ref.exists(stateProvider), false);
    });
  });

  group('getActiveProviders', () {
    test('Should return no active providers', () {
      final ref = RefenaContainer();
      expect(ref.getActiveProviders(), isEmpty);
    });

    test('Should return one active provider', () {
      final ref = RefenaContainer();
      final stateProvider = StateProvider((ref) => 10);
      expect(ref.getActiveProviders(), isEmpty);
      ref.read(stateProvider);
      expect(ref.getActiveProviders(), [stateProvider]);
    });

    test('Should include globalRedux provider', () {
      final ref = RefenaContainer();
      final stateProvider = StateProvider((ref) => 10);
      expect(ref.getActiveProviders(), isEmpty);
      ref.read(stateProvider);
      ref.read(globalReduxProvider);
      expect(ref.getActiveProviders(), [stateProvider, globalReduxProvider]);
    });
  });
}

class _DummyClass {
  final int value;

  _DummyClass(this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _DummyClass && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
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
  }
}

class _DisposableObserver extends RefenaObserver {
  bool _disposed = false;

  @override
  void handleEvent(RefenaEvent event) {}

  @override
  void dispose() {
    _disposed = true;
  }
}
