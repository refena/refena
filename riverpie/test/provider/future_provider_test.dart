import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  test('Should read the value', () async {
    final provider = FutureProvider((ref) => Future.value(123));
    final observer = RiverpieHistoryObserver();
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(provider), AsyncValue<int>.loading());
    expect(await ref.future(provider), 123);
    expect(
      ref.read(provider),
      AsyncValue.withData(123),
    );

    // Check events
    final notifier =
        ref.anyNotifier<FutureProviderNotifier<int>, AsyncValue<int>>(
      provider,
    );
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: AsyncValue<int>.loading(),
      ),
      ChangeEvent(
        notifier: notifier,
        prev: AsyncValue<int>.loading(),
        next: AsyncValue.withData(123),
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
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(providerC), AsyncValue<String>.loading());
    expect(await ref.future(providerC), 'AAA BBB CCC');
    expect(
      ref.read(providerC),
      AsyncValue.withData('AAA BBB CCC'),
    );

    // Check events
    final notifierA =
        ref.anyNotifier<FutureProviderNotifier<String>, AsyncValue<String>>(
      providerA,
    );
    final notifierB =
        ref.anyNotifier<FutureProviderNotifier<String>, AsyncValue<String>>(
      providerB,
    );
    final notifierC =
        ref.anyNotifier<FutureProviderNotifier<String>, AsyncValue<String>>(
      providerC,
    );

    // providerA and providerB are initialized immediately
    // providerC is initialized after the await of providerA
    expect(observer.history, [
      ProviderInitEvent(
        provider: providerA,
        notifier: notifierA,
        cause: ProviderInitCause.access,
        value: AsyncValue<String>.loading(),
      ),
      ProviderInitEvent(
        provider: providerC,
        notifier: notifierC,
        cause: ProviderInitCause.access,
        value: AsyncValue<String>.loading(),
      ),
      ChangeEvent(
        notifier: notifierA,
        prev: AsyncValue<String>.loading(),
        next: AsyncValue.withData('AAA'),
        flagRebuild: [],
      ),
      ProviderInitEvent(
        provider: providerB,
        notifier: notifierB,
        cause: ProviderInitCause.access,
        value: AsyncValue<String>.loading(),
      ),
      ChangeEvent(
        notifier: notifierB,
        prev: AsyncValue<String>.loading(),
        next: AsyncValue.withData('BBB'),
        flagRebuild: [],
      ),
      ChangeEvent(
        notifier: notifierC,
        prev: AsyncValue<String>.loading(),
        next: AsyncValue.withData('AAA BBB CCC'),
        flagRebuild: [],
      ),
    ]);
  });
}
