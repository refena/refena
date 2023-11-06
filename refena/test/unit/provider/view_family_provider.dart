import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Should compile with family shorthand', () async {
    final ref = RefenaContainer();

    final provider = ViewProvider.family<int, int>((ref, param) => param * 2);
    final notifier = ref.anyNotifier(provider);

    expect(notifier.isParamInitialized(123), false);
    expect(ref.read(provider(123)), 246);
    expect(notifier.isParamInitialized(123), true);
  });

  test('Should init param on ref.read', () async {
    final ref = RefenaContainer();

    final provider = ViewFamilyProvider<int, int>((ref, param) => param * 2);
    final notifier = ref.anyNotifier(provider);

    expect(notifier.isParamInitialized(123), false);
    expect(ref.read(provider(123)), 246);
    expect(notifier.isParamInitialized(123), true);
  });

  test('Should rebuild on dependency change', () async {
    final ref = RefenaContainer();

    final stateProvider = StateProvider((ref) => 10);
    final provider = ViewFamilyProvider<int, int>((ref, param) {
      return param * 2 + ref.watch(stateProvider);
    });
    final notifier = ref.anyNotifier(provider);

    expect(notifier.isParamInitialized(100), false);
    expect(ref.read(provider(100)), 210);
    expect(notifier.isParamInitialized(100), true);

    // trigger rebuild
    ref.notifier(stateProvider).setState((_) => 20);
    await skipAllMicrotasks();

    expect(notifier.isParamInitialized(100), true);
    expect(ref.read(provider(100)), 220);
    expect(notifier.getTempProviders(), [
      isA<ViewProvider<int>>(),
    ]);
    expect(ref.getActiveProviders(), {
      provider,
      stateProvider,
      notifier.getTempProviders().first,
    });

    // dispose
    ref.disposeFamilyParam(provider, 100);
    expect(notifier.isParamInitialized(100), false);
    expect(notifier.getTempProviders(), isEmpty);
    expect(ref.getActiveProviders(), {
      provider,
      stateProvider,
    });

    // change state (should not rebuild)
    ref.notifier(stateProvider).setState((_) => 30);
    await skipAllMicrotasks();

    expect(notifier.isParamInitialized(100), false);
    expect(notifier.getTempProviders(), isEmpty);
    expect(ref.getActiveProviders(), {
      provider,
      stateProvider,
    });
  });

  test('Changing param should work', () async {
    final ref = RefenaContainer();

    final doubleProvider = ViewFamilyProvider<int, int>((ref, param) {
      return param * 2;
    });
    final stateProvider = StateProvider((ref) => 10);
    final viewProvider = ViewProvider((ref) {
      final param = ref.watch(stateProvider);
      return ref.watch(doubleProvider(param));
    });

    final doubleNotifier = ref.anyNotifier(doubleProvider);
    expect(doubleNotifier.isParamInitialized(10), false);
    expect(ref.getActiveProviders(), {
      doubleProvider,
    });

    // Init param
    expect(ref.read(viewProvider), 20);
    expect(doubleNotifier.getTempProviders().length, 1);
    expect(doubleNotifier.isParamInitialized(10), true);
    expect(ref.getActiveProviders(), {
      doubleProvider,
      viewProvider,
      stateProvider,
      doubleNotifier.getTempProviders().first,
    });

    // Change state
    ref.notifier(stateProvider).setState((_) => 20);
    await skipAllMicrotasks();

    expect(ref.read(viewProvider), 40);
    expect(doubleNotifier.getTempProviders().length, 2);
    expect(doubleNotifier.isParamInitialized(10), true);
    expect(doubleNotifier.isParamInitialized(20), true);
    expect(ref.getActiveProviders(), {
      doubleProvider,
      viewProvider,
      stateProvider,
      doubleNotifier.getTempProviders().first,
      doubleNotifier.getTempProviders().last,
    });

    // Dispose family provider (should also dispose all temporary providers)
    ref.dispose(doubleProvider);
    expect(doubleNotifier.getTempProviders(), isEmpty);
    expect(ref.getActiveProviders(), {
      stateProvider,
    });
  });

  test('Should read family with select', () async {
    final ref = RefenaContainer();
    final provider = ViewFamilyProvider<int, int>((ref, param) => param * 2);
    final notifier = ref.anyNotifier(provider);

    expect(notifier.isParamInitialized(10), false);

    final selected = ref.read(provider(10).select((state) => state - 5));

    expect(selected, 15);
    expect(notifier.isParamInitialized(10), true);
    expect(ref.getActiveProviders(), {
      provider,
      notifier.getTempProviders().first,
    });
  });
}
