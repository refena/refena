import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Should compile with family shorthand', () async {
    final ref = RefenaContainer();

    final provider = FutureProvider.family<int, int>((ref, param) async {
      return param * 2;
    });
    final notifier = ref.anyNotifier(provider);

    expect(notifier.isParamInitialized(123), false);
    expect(ref.read(provider(123)), AsyncValue<int>.loading());
    await skipAllMicrotasks();
    expect(notifier.isParamInitialized(123), true);
    expect(ref.read(provider(123)), AsyncValue.data(246));
  });

  test('Should read the value', () async {
    final doubleProvider = FutureFamilyProvider<int, int>((ref, param) async {
      await Future.delayed(Duration(milliseconds: 50));
      return Future.value(param * 2);
    });
    final viewProvider = ViewProvider((ref) {
      return ref.watch(doubleProvider(123));
    });
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(viewProvider), AsyncValue<int>.loading());
    await Future.delayed(Duration(milliseconds: 100));
    expect(
      ref.read(viewProvider),
      AsyncValue.data(246),
    );

    // Check events
    final doubleNotifier = ref.anyNotifier(doubleProvider);
    final viewNotifier = ref.anyNotifier(viewProvider);

    expect(observer.history.length, 5);

    final history0 = observer.history[0] as ProviderInitEvent;
    expect(history0.provider, doubleProvider);
    expect(history0.notifier, doubleNotifier);
    expect(history0.cause, ProviderInitCause.access);
    expect(history0.value, {});

    final history1 =
        observer.history[1] as ChangeEvent<Map<int, AsyncValue<int>>>;
    expect(history1.notifier, doubleNotifier);
    expect(history1.action, null);
    expect(history1.prev, {});
    expect(history1.next, {123: AsyncValue<int>.loading()});
    expect(history1.rebuild, []);

    final history2 = observer.history[2] as ProviderInitEvent;
    expect(history2.provider, viewProvider);
    expect(history2.notifier, viewNotifier);
    expect(history2.cause, ProviderInitCause.access);
    expect(history2.value, AsyncValue<int>.loading());

    final history3 =
        observer.history[3] as ChangeEvent<Map<int, AsyncValue<int>>>;
    expect(history3.notifier, doubleNotifier);
    expect(history3.action, null);
    expect(history3.prev, {123: AsyncValue<int>.loading()});
    expect(history3.next, {123: AsyncValue.data(246)});
    expect(history3.rebuild, [viewNotifier]);

    final history4 = observer.history[4] as RebuildEvent<AsyncValue<int>>;
    expect(history4.rebuildable, viewNotifier);
    expect(history4.causes.length, 1);
    expect(history4.causes[0], history3);
    expect(history4.prev, AsyncValue<int>.loading());
    expect(history4.next, AsyncValue.data(246));
    expect(history4.rebuild, []);

    final view2Provider = ViewProvider((ref) {
      return ref.watch(doubleProvider(400));
    });
    expect(ref.read(view2Provider), AsyncValue<int>.loading());
    await Future.delayed(Duration(milliseconds: 100));
    expect(
      ref.read(viewProvider),
      AsyncValue.data(246),
    );
    expect(
      ref.read(view2Provider),
      AsyncValue.data(800),
    );
  });

  test('Should update the listener config', () async {
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    final doubleProvider = FutureFamilyProvider<int, int>((ref, param) async {
      await Future.delayed(Duration(milliseconds: 50));
      return Future.value(param * 2);
    });
    final stateProvider = StateProvider((ref) => 123);
    final viewProvider = ViewProvider((ref) {
      final param = ref.watch(stateProvider);
      return ref.watch(doubleProvider(param));
    });

    // decoy provider (it should not rebuild)
    final decoyProvider = ViewProvider((ref) {
      return ref.watch(doubleProvider(123));
    });

    expect(ref.read(viewProvider), AsyncValue<int>.loading());
    await Future.delayed(Duration(milliseconds: 100));
    expect(
      ref.read(viewProvider),
      AsyncValue.data(246),
    );
    expect(
      ref.read(decoyProvider),
      AsyncValue.data(246), // it should use cached result of 123
    );

    // trigger rebuild
    ref.notifier(stateProvider).setState((old) => 100);
    await skipAllMicrotasks();
    expect(ref.read(viewProvider), AsyncValue<int>.loading());
    expect(
      ref.read(decoyProvider),
      AsyncValue.data(246),
    );

    await Future.delayed(Duration(milliseconds: 100));
    expect(
      ref.read(viewProvider),
      AsyncValue.data(200),
    );
    expect(
      ref.read(decoyProvider),
      AsyncValue.data(246),
    );

    // Check events
    final viewNotifier = ref.anyNotifier(viewProvider);
    expect(
      observer.history
          .whereType<RebuildEvent>()
          .where((e) => e.rebuildable == viewNotifier)
          .length,
      3,
    );

    final decoyNotifier = ref.anyNotifier(decoyProvider);
    expect(
      observer.history
          .whereType<RebuildEvent>()
          .where((e) => e.rebuildable == decoyNotifier)
          .length,
      0,
    );
  });

  test('Should read family with select', () async {
    final ref = RefenaContainer();
    final provider = FutureFamilyProvider<int, int>((ref, param) async {
      return param * 2;
    });
    final notifier = ref.anyNotifier(provider);

    expect(notifier.isParamInitialized(10), false);
    expect(ref.read(provider(10)), AsyncValue<int>.loading());
    expect(notifier.isParamInitialized(10), true);

    await skipAllMicrotasks();

    expect(ref.read(provider(10)), AsyncValue.data(20));

    final selected = ref.read(provider(10).select((state) => state.data! - 5));
    expect(selected, 15);
    expect(notifier.isParamInitialized(10), true);
  });
}
