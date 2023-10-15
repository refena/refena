import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  test('Should read the value', () async {
    final provider = FutureProvider((ref) => Future.value(123));
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), AsyncValue<int>.loading());
    expect(await ref.future(provider), 123);
    expect(
      ref.read(provider),
      AsyncValue.data(123),
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
        action: null,
        prev: AsyncValue<int>.loading(),
        next: AsyncValue.data(123),
        rebuild: [],
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
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(providerC), AsyncValue<String>.loading());
    expect(await ref.future(providerC), 'AAA BBB CCC');
    expect(
      ref.read(providerC),
      AsyncValue.data('AAA BBB CCC'),
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
        action: null,
        prev: AsyncValue<String>.loading(),
        next: AsyncValue.data('AAA'),
        rebuild: [],
      ),
      ProviderInitEvent(
        provider: providerB,
        notifier: notifierB,
        cause: ProviderInitCause.access,
        value: AsyncValue<String>.loading(),
      ),
      ChangeEvent(
        notifier: notifierB,
        action: null,
        prev: AsyncValue<String>.loading(),
        next: AsyncValue.data('BBB'),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: notifierC,
        action: null,
        prev: AsyncValue<String>.loading(),
        next: AsyncValue.data('AAA BBB CCC'),
        rebuild: [],
      ),
    ]);
  });
}
