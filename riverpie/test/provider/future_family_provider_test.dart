import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  test('Should read the value', () async {
    final doubleProvider = FutureFamilyProvider<int, int>((ref, param) async {
      await Future.delayed(Duration(milliseconds: 50));
      return Future.value(param * 2);
    });
    final viewProvider = ViewProvider((ref) {
      return ref.watch(doubleProvider(123));
    });
    final observer = RiverpieHistoryObserver.all();
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(viewProvider), AsyncValue<int>.loading());
    await Future.delayed(Duration(milliseconds: 100));
    expect(
      ref.read(viewProvider),
      AsyncValue.withData(246),
    );

    // Check events
    final doubleNotifier = ref.anyNotifier(doubleProvider);
    final viewNotifier = ref.anyNotifier(viewProvider);

    expect(observer.history.length, 6);

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

    final history2 = observer.history[2] as ListenerAddedEvent;
    expect(history2.notifier, doubleNotifier);
    expect(history2.rebuildable, viewNotifier);

    final history3 = observer.history[3] as ProviderInitEvent;
    expect(history3.provider, viewProvider);
    expect(history3.notifier, viewNotifier);
    expect(history3.cause, ProviderInitCause.access);
    expect(history3.value, AsyncValue<int>.loading());

    final history4 =
        observer.history[4] as ChangeEvent<Map<int, AsyncValue<int>>>;
    expect(history4.notifier, doubleNotifier);
    expect(history4.action, null);
    expect(history4.prev, {123: AsyncValue<int>.loading()});
    expect(history4.next, {123: AsyncValue.withData(246)});
    expect(history4.rebuild, [viewNotifier]);

    final history5 = observer.history[5] as ChangeEvent<AsyncValue<int>>;
    expect(history5.notifier, viewNotifier);
    expect(history5.action, null);
    expect(history5.prev, AsyncValue<int>.loading());
    expect(history5.next, AsyncValue.withData(246));
    expect(history5.rebuild, []);

    final view2Provider = ViewProvider((ref) {
      return ref.watch(doubleProvider(400));
    });
    expect(ref.read(view2Provider), AsyncValue<int>.loading());
    await Future.delayed(Duration(milliseconds: 100));
    expect(
      ref.read(viewProvider),
      AsyncValue.withData(246),
    );
    expect(
      ref.read(view2Provider),
      AsyncValue.withData(800),
    );
  });
}
