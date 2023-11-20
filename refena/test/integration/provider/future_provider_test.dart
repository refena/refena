import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Should provide an async value', () async {
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    final provider = FutureProvider((ref) => Future.value(123));
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

  test('Should await other FutureProviders', () async {
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    final parentProviderA = FutureProvider(
      (ref) => Future.delayed(Duration(milliseconds: 50), () => 'AAA'),
    );

    final parentProviderB = FutureProvider(
      (ref) => Future.delayed(Duration(milliseconds: 100), () => 'BBB'),
    );

    final childProvider = FutureProvider(
      (ref) async {
        final a = await ref.future(parentProviderA);
        final b = await ref.future(parentProviderB);
        return '$a $b CCC';
      },
    );

    expect(ref.read(childProvider), AsyncValue<String>.loading());

    expect(await ref.future(childProvider), 'AAA BBB CCC');
    expect(
      ref.read(childProvider),
      AsyncValue.data('AAA BBB CCC'),
    );

    // Check events
    final parentNotifierA =
        ref.anyNotifier<FutureProviderNotifier<String>, AsyncValue<String>>(
      parentProviderA,
    );
    final parentNotifierB =
        ref.anyNotifier<FutureProviderNotifier<String>, AsyncValue<String>>(
      parentProviderB,
    );
    final childNotifier =
        ref.anyNotifier<FutureProviderNotifier<String>, AsyncValue<String>>(
      childProvider,
    );

    // providerA and providerB are initialized immediately
    // providerC is initialized after the await of providerA
    expect(observer.history, [
      ProviderInitEvent(
        provider: parentProviderA,
        notifier: parentNotifierA,
        cause: ProviderInitCause.access,
        value: AsyncValue<String>.loading(),
      ),
      ProviderInitEvent(
        provider: childProvider,
        notifier: childNotifier,
        cause: ProviderInitCause.access,
        value: AsyncValue<String>.loading(),
      ),
      ChangeEvent(
        notifier: parentNotifierA,
        action: null,
        prev: AsyncValue<String>.loading(),
        next: AsyncValue.data('AAA'),
        rebuild: [],
      ),
      ProviderInitEvent(
        provider: parentProviderB,
        notifier: parentNotifierB,
        cause: ProviderInitCause.access,
        value: AsyncValue<String>.loading(),
      ),
      ChangeEvent(
        notifier: parentNotifierB,
        action: null,
        prev: AsyncValue<String>.loading(),
        next: AsyncValue.data('BBB'),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: childNotifier,
        action: null,
        prev: AsyncValue<String>.loading(),
        next: AsyncValue.data('AAA BBB CCC'),
        rebuild: [],
      ),
    ]);
  });

  test('Should rebuild on parent change', () async {
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    final parentProvider = StateProvider((ref) => 0);
    final childProvider = FutureProvider((ref) async {
      final value = ref.watch(parentProvider);
      await Future.delayed(Duration(milliseconds: 50));
      return value * 2;
    });

    expect(ref.read(childProvider), AsyncValue<int>.loading());

    expect(await ref.future(childProvider), 0);
    expect(
      ref.read(childProvider),
      AsyncValue.data(0),
    );

    final parentNotifier = ref.anyNotifier<StateNotifier<int>, int>(
      parentProvider,
    );
    final childNotifier =
        ref.anyNotifier<FutureProviderNotifier<int>, AsyncValue<int>>(
      childProvider,
    );

    // Check dependency graph
    expect(parentNotifier.dependencies, isEmpty);
    expect(parentNotifier.dependents, {childNotifier});
    expect(childNotifier.dependencies, {parentNotifier});
    expect(childNotifier.dependents, isEmpty);

    // Change parent
    ref.notifier(parentProvider).setState((old) => 10);
    await skipAllMicrotasks();

    expect(ref.read(childProvider), AsyncValue<int>.loading(0));

    expect(await ref.future(childProvider), 20);
    expect(
      ref.read(childProvider),
      AsyncValue.data(20),
    );

    // Check events
    expect(observer.history, [
      ProviderInitEvent(
        provider: parentProvider,
        notifier: parentNotifier,
        cause: ProviderInitCause.access,
        value: 0,
      ),
      ProviderInitEvent(
        provider: childProvider,
        notifier: childNotifier,
        cause: ProviderInitCause.access,
        value: AsyncValue<int>.loading(),
      ),
      ChangeEvent(
        notifier: childNotifier,
        action: null,
        prev: AsyncValue<int>.loading(),
        next: AsyncValue.data(0),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: parentNotifier,
        action: null,
        prev: 0,
        next: 10,
        rebuild: [childNotifier],
      ),
      RebuildEvent(
        rebuildable: childNotifier,
        causes: [
          ChangeEvent<int>(
            notifier: parentNotifier,
            action: null,
            prev: 0,
            next: 10,
            rebuild: [childNotifier],
          ),
        ],
        prev: AsyncValue.data(0),
        next: AsyncValue<int>.loading(0),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: childNotifier,
        action: null,
        prev: AsyncValue<int>.loading(0),
        next: AsyncValue.data(20),
        rebuild: [],
      ),
    ]);
  });

  test('Should trigger onChanged', () async {
    final provider = FutureProvider(
      (ref) => Future.value(123),
      onChanged: (prev, next, ref) => ref.message('Change from $prev to $next'),
    );
    final observer = RefenaHistoryObserver.only(
      message: true,
    );
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), AsyncValue<int>.loading());
    expect(await ref.future(provider), 123);
    expect(
      ref.read(provider),
      AsyncValue.data(123),
    );

    expect(observer.messages, isEmpty);
    await skipAllMicrotasks();

    expect(observer.messages, [
      'Change from AsyncLoading<int> to AsyncData<int>(123)',
    ]);
  });
}
