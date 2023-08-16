import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpie/riverpie.dart';
import 'package:riverpie/src/notifier/types/future_provider_notifier.dart';

void main() {
  group(FutureProvider, () {
    test('Should read the value', () async {
      final provider = FutureProvider((ref) => Future.value(123));
      final observer = RiverpieHistoryObserver();
      final scope = RiverpieScope(
        observer: observer,
        child: Container(),
      );

      expect(scope.read(provider), AsyncSnapshot<int>.waiting());
      expect(await scope.future(provider), 123);
      expect(
        scope.read(provider),
        AsyncSnapshot.withData(ConnectionState.done, 123),
      );

      // Check events
      final notifier =
          scope.anyNotifier<FutureProviderNotifier<int>, AsyncSnapshot<int>>(
        provider,
      );
      expect(observer.history, [
        ProviderInitEvent(
          provider: provider,
          notifier: notifier,
          cause: ProviderInitCause.access,
          value: AsyncSnapshot<int>.waiting(),
        ),
        ChangeEvent(
          notifier: notifier,
          prev: AsyncSnapshot<int>.waiting(),
          next: AsyncSnapshot.withData(ConnectionState.done, 123),
          flagRebuild: [],
        ),
      ]);
    });

    test('Should read the nested value', () async {
      final providerA = FutureProvider(
        (ref) => Future.delayed(
          Duration(milliseconds: 50),
          () => 'AAA',
        ),
        debugLabel: 'providerA',
      );
      final providerB = FutureProvider(
        (ref) => Future.delayed(
          Duration(milliseconds: 100),
          () => 'BBB',
        ),
        debugLabel: 'providerB',
      );
      final providerC = FutureProvider((ref) async {
        final a = await ref.future(providerA);
        final b = await ref.future(providerB);
        return '$a $b CCC';
      }, debugLabel: 'providerC');
      final observer = RiverpieHistoryObserver();
      final scope = RiverpieScope(
        observer: observer,
        child: Container(),
      );

      expect(scope.read(providerC), AsyncSnapshot<String>.waiting());
      expect(await scope.future(providerC), 'AAA BBB CCC');
      expect(
        scope.read(providerC),
        AsyncSnapshot.withData(ConnectionState.done, 'AAA BBB CCC'),
      );

      // Check events
      final notifierA = scope
          .anyNotifier<FutureProviderNotifier<String>, AsyncSnapshot<String>>(
        providerA,
      );
      final notifierB = scope
          .anyNotifier<FutureProviderNotifier<String>, AsyncSnapshot<String>>(
        providerB,
      );
      final notifierC = scope
          .anyNotifier<FutureProviderNotifier<String>, AsyncSnapshot<String>>(
        providerC,
      );

      // providerA and providerB are initialized immediately
      // providerC is initialized after the await of providerA
      expect(observer.history, [
        ProviderInitEvent(
          provider: providerA,
          notifier: notifierA,
          cause: ProviderInitCause.access,
          value: AsyncSnapshot<String>.waiting(),
        ),
        ProviderInitEvent(
          provider: providerC,
          notifier: notifierC,
          cause: ProviderInitCause.access,
          value: AsyncSnapshot<String>.waiting(),
        ),
        ChangeEvent(
          notifier: notifierA,
          prev: AsyncSnapshot<String>.waiting(),
          next: AsyncSnapshot.withData(ConnectionState.done, 'AAA'),
          flagRebuild: [],
        ),
        ProviderInitEvent(
          provider: providerB,
          notifier: notifierB,
          cause: ProviderInitCause.access,
          value: AsyncSnapshot<String>.waiting(),
        ),
        ChangeEvent(
          notifier: notifierB,
          prev: AsyncSnapshot<String>.waiting(),
          next: AsyncSnapshot.withData(ConnectionState.done, 'BBB'),
          flagRebuild: [],
        ),
        ChangeEvent(
          notifier: notifierC,
          prev: AsyncSnapshot<String>.waiting(),
          next: AsyncSnapshot.withData(ConnectionState.done, 'AAA BBB CCC'),
          flagRebuild: [],
        ),
      ]);
    });
  });
}
