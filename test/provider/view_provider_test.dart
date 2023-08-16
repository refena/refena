import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpie/riverpie.dart';
import 'package:riverpie/src/notifier/types/view_provider_notifier.dart';

void main() {
  group(ViewProvider, () {
    test('Single provider test', () {
      final provider = ViewProvider((ref) => 123);
      final observer = RiverpieHistoryObserver();
      final scope = RiverpieScope(
        observer: observer,
        child: Container(),
      );

      expect(scope.read(provider), 123);

      // Check events
      final notifier =
          scope.anyNotifier<ViewProviderNotifier<int>, int>(provider);
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
      final scope = RiverpieScope(
        observer: observer,
        child: Container(),
      );

      expect(scope.read(stateProvider), 0);
      expect(scope.read(viewProvider), 100);

      scope.notifier(stateProvider).setState((old) => old + 1);

      // wait for the microtasks to be executed
      await Future.delayed(Duration.zero);

      expect(scope.read(stateProvider), 1);
      expect(scope.read(viewProvider), 101);

      // Check events
      final stateNotifier = scope.notifier(stateProvider);
      final viewNotifier =
          scope.anyNotifier<ViewProviderNotifier<int>, int>(viewProvider);

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
  });
}
