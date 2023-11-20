import 'dart:async';

import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Single provider test', () async {
    final controller = StreamController<int>();
    final provider = StreamProvider((ref) => controller.stream);
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), AsyncValue<int>.loading());

    controller.add(123);
    await skipAllMicrotasks();

    expect(ref.read(provider), AsyncValue<int>.data(123));

    // Check events
    final notifier = ref.anyNotifier(provider);
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
        next: AsyncValue<int>.data(123),
        rebuild: [],
      ),
    ]);
  });

  test('Should rebuild on parent change', () async {
    final parentProvider = StateProvider((ref) => 0);
    final childProvider = StreamProvider((ref) async* {
      final value = ref.watch(parentProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      yield value + 1;
    });

    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(childProvider), AsyncValue<int>.loading());

    final parentNotifier = ref.notifier(parentProvider);
    final childNotifier = ref.anyNotifier(childProvider);

    // Check dependency graph (before)
    expect(parentNotifier.dependencies, isEmpty);
    expect(parentNotifier.dependents, isEmpty);
    expect(childNotifier.dependencies, isEmpty);
    expect(childNotifier.dependents, isEmpty);

    expect(ref.read(parentProvider), 0);

    expect(await ref.future(childProvider), 1);
    expect(ref.read(childProvider), AsyncValue<int>.data(1));

    // Check dependency graph (after)
    expect(parentNotifier.dependencies, isEmpty);
    expect(parentNotifier.dependents, {childNotifier});
    expect(childNotifier.dependencies, {parentNotifier});
    expect(childNotifier.dependents, isEmpty);

    // Trigger rebuild
    ref.notifier(parentProvider).setState((old) => 10);
    expect(ref.read(parentProvider), 10);

    expect(ref.read(childProvider), AsyncValue<int>.data(1));
    await skipAllMicrotasks();
    expect(ref.read(childProvider), AsyncValue<int>.loading(1));

    expect(await ref.future(childProvider), 11);
    expect(ref.read(childProvider), AsyncValue<int>.data(11));
  });

  test('Rebuild should clear old dependencies', () async {
    // Copied from future_provider_test.dart but with StreamProvider

    final ref = RefenaContainer();

    late Completer<void> bridgeCompleter;
    late Completer<void> bCompleter;
    final parentProviderA = StateProvider((ref) => 1);
    final parentProviderB = StateProvider((ref) => 2);
    final parentProviderC = StateProvider((ref) => 3);
    final bridgeProvider = StateProvider((ref) => false);
    final childProvider = StreamProvider((ref) async* {
      bridgeCompleter = Completer<void>();

      await Future.delayed(Duration(milliseconds: 50));
      final bridge = ref.watch(bridgeProvider);
      bridgeCompleter.complete();
      if (bridge) {
        final c = ref.watch(parentProviderC);
        yield c;
      } else {
        final a = ref.watch(parentProviderA);
        bCompleter = Completer<void>();
        await Future.delayed(Duration(milliseconds: 50));
        bCompleter.complete();
        final b = ref.watch(parentProviderB);
        yield a + b;
      }
    });

    final parentNotifierA = ref.anyNotifier(parentProviderA);
    final parentNotifierB = ref.anyNotifier(parentProviderB);
    final parentNotifierC = ref.anyNotifier(parentProviderC);
    final bridgeNotifier = ref.anyNotifier(bridgeProvider);
    final childNotifier = ref.anyNotifier(childProvider);

    // Check dependency graph (before)
    expect(parentNotifierA.dependencies, isEmpty);
    expect(parentNotifierA.dependents, isEmpty);
    expect(parentNotifierB.dependencies, isEmpty);
    expect(parentNotifierB.dependents, isEmpty);
    expect(parentNotifierC.dependencies, isEmpty);
    expect(parentNotifierC.dependents, isEmpty);
    expect(bridgeNotifier.dependencies, isEmpty);
    expect(bridgeNotifier.dependents, isEmpty);
    expect(childNotifier.dependencies, isEmpty);
    expect(childNotifier.dependents, isEmpty);

    await skipAllMicrotasks();
    await bridgeCompleter.future;

    // Check dependency graph (bridge)
    expect(parentNotifierA.dependencies, isEmpty);
    expect(parentNotifierA.dependents, {childNotifier});
    expect(parentNotifierB.dependencies, isEmpty);
    expect(parentNotifierB.dependents, isEmpty);
    expect(parentNotifierC.dependencies, isEmpty);
    expect(parentNotifierC.dependents, isEmpty);
    expect(bridgeNotifier.dependencies, isEmpty);
    expect(bridgeNotifier.dependents, {childNotifier});
    expect(childNotifier.dependencies, {parentNotifierA, bridgeNotifier});
    expect(childNotifier.dependents, isEmpty);

    // Change bridge
    ref.notifier(bridgeProvider).setState((old) => true);
    await skipAllMicrotasks();

    // Check dependency graph (after change bridge)
    expect(parentNotifierA.dependencies, isEmpty);
    expect(parentNotifierA.dependents, isEmpty);
    expect(parentNotifierB.dependencies, isEmpty);
    expect(parentNotifierB.dependents, isEmpty);
    expect(parentNotifierC.dependencies, isEmpty);
    expect(parentNotifierC.dependents, isEmpty);
    expect(bridgeNotifier.dependencies, isEmpty);
    expect(bridgeNotifier.dependents, isEmpty);
    expect(childNotifier.dependencies, isEmpty);
    expect(childNotifier.dependents, isEmpty);

    await bridgeCompleter.future;
    await bCompleter.future;

    // Check dependency graph (after bridge future)
    expect(parentNotifierA.dependencies, isEmpty);
    expect(parentNotifierA.dependents, isEmpty);
    expect(parentNotifierB.dependencies, isEmpty);
    expect(parentNotifierB.dependents, isEmpty);
    expect(parentNotifierC.dependencies, isEmpty);
    expect(parentNotifierC.dependents, {childNotifier});
    expect(bridgeNotifier.dependencies, isEmpty);
    expect(bridgeNotifier.dependents, {childNotifier});
    expect(childNotifier.dependencies, {parentNotifierC, bridgeNotifier});
    expect(childNotifier.dependents, isEmpty);
  });

  test('Should trigger onChanged', () async {
    final controller = StreamController<int>();
    final provider = StreamProvider(
      (ref) => controller.stream,
      onChanged: (prev, next, ref) => ref.message('Change from $prev to $next'),
    );
    final observer = RefenaHistoryObserver.only(
      message: true,
    );
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), AsyncValue<int>.loading());

    controller.add(123);
    await skipAllMicrotasks();

    expect(ref.read(provider), AsyncValue<int>.data(123));
    expect(observer.messages, [
      'Change from AsyncLoading<int> to AsyncData<int>(123)',
    ]);
  });
}
