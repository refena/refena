import 'package:riverpie/riverpie.dart';
import 'package:riverpie/src/notifier/types/view_provider_notifier.dart';
import 'package:test/test.dart';

import '../util/skip_microtasks.dart';

void main() {
  test('Single provider test', () {
    final provider = ViewProvider((ref) => 123);
    final observer = RiverpieHistoryObserver();
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(provider), 123);

    // Check events
    final notifier = ref.anyNotifier<ViewProviderNotifier<int>, int>(provider);
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: 123,
      ),
    ]);
  });

  test('Multiple provider test', () async {
    final stateProvider = StateProvider((ref) => 0);
    final viewProvider = ViewProvider((ref) {
      final state = ref.watch(stateProvider);
      return state + 100;
    });
    final observer = RiverpieHistoryObserver();
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(stateProvider), 0);
    expect(ref.read(viewProvider), 100);

    ref.notifier(stateProvider).setState((old) => old + 1);

    await skipAllMicrotasks();

    expect(ref.read(stateProvider), 1);
    expect(ref.read(viewProvider), 101);

    // Check events
    final stateNotifier = ref.notifier(stateProvider);
    final viewNotifier =
        ref.anyNotifier<ViewProviderNotifier<int>, int>(viewProvider);

    expect(observer.history, [
      ProviderInitEvent(
        provider: stateProvider,
        notifier: stateNotifier,
        cause: ProviderInitCause.access,
        value: 0,
      ),
      ListenerAddedEvent(
        notifier: stateNotifier,
        rebuildable: viewNotifier,
      ),
      ProviderInitEvent(
        provider: viewProvider,
        notifier: viewNotifier,
        cause: ProviderInitCause.access,
        value: 100,
      ),
      ChangeEvent(
        notifier: stateNotifier,
        prev: 0,
        next: 1,
        flagRebuild: [viewNotifier],
      ),
      ChangeEvent(
        notifier: viewNotifier,
        prev: 100,
        next: 101,
        flagRebuild: [],
      ),
    ]);
  });
}
