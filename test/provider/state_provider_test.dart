import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpie/riverpie.dart';

void main() {
  group(StateProvider, () {
    test('Single provider test', () {
      final provider = StateProvider((ref) => 123);
      final observer = RiverpieHistoryObserver();
      final scope = RiverpieScope(
        observer: observer,
        child: Container(),
      );

      expect(scope.read(provider), 123);

      scope.notifier(provider).setState((old) => old + 1);

      expect(scope.read(provider), 124);

      // Check events
      final notifier = scope.notifier(provider);
      expect(observer.history, [
        ProviderInitEvent(
          provider: provider,
          notifier: notifier,
          cause: ProviderInitCause.access,
          value: 123,
        ),
        ChangeEvent(
          notifier: notifier,
          prev: 123,
          next: 124,
          flagRebuild: [],
        ),
      ]);
    });
  });
}
