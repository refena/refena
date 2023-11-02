import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Should provide single constant', () {
    final provider = ViewProvider((ref) => 123);
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
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

  test('Should rebuild based on watched provider', () async {
    final stateProvider = StateProvider((ref) => 0);
    final viewProvider = ViewProvider((ref) {
      final state = ref.watch(stateProvider);
      return state + 100;
    });
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
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
      ProviderInitEvent(
        provider: viewProvider,
        notifier: viewNotifier,
        cause: ProviderInitCause.access,
        value: 100,
      ),
      ChangeEvent(
        notifier: stateNotifier,
        action: null,
        prev: 0,
        next: 1,
        rebuild: [viewNotifier],
      ),
      RebuildEvent(
        rebuildable: viewNotifier,
        causes: [
          ChangeEvent<int>(
            notifier: stateNotifier,
            action: null,
            prev: 0,
            next: 1,
            rebuild: [viewNotifier],
          ),
        ],
        prev: 100,
        next: 101,
        rebuild: [],
      ),
    ]);
  });

  test('Multiple provider test with provider.select', () async {
    // Providers
    final numberProvider = StateProvider((ref) => 0);
    final stringProvider = StateProvider((ref) => 'a');
    final viewProvider = ViewProvider((ref) {
      final n = ref.watch(numberProvider);
      final s = ref.watch(stringProvider);
      return _ComplexState(n, s);
    });
    final selectiveViewProvider = ViewProvider((ref) {
      return ref.watch(viewProvider.select((state) => state.string));
    });

    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(viewProvider), _ComplexState(0, 'a'));
    expect(ref.read(selectiveViewProvider), 'a');

    // Update state
    ref.notifier(numberProvider).setState((old) => old + 1);
    await skipAllMicrotasks();

    expect(ref.read(numberProvider), 1);
    expect(ref.read(stringProvider), 'a');
    expect(ref.read(viewProvider), _ComplexState(1, 'a'));
    expect(ref.read(selectiveViewProvider), 'a');

    // Update state
    ref.notifier(stringProvider).setState((old) => '${old}b');
    await skipAllMicrotasks();

    expect(ref.read(numberProvider), 1);
    expect(ref.read(stringProvider), 'ab');
    expect(ref.read(viewProvider), _ComplexState(1, 'ab'));
    expect(ref.read(selectiveViewProvider), 'ab');

    // Check events
    final numberNotifier = ref.notifier(numberProvider);
    final stringNotifier = ref.notifier(stringProvider);
    final viewNotifier =
        ref.anyNotifier<ViewProviderNotifier<_ComplexState>, _ComplexState>(
            viewProvider);
    final selectiveViewNotifier =
        ref.anyNotifier<ViewProviderNotifier<String>, String>(
            selectiveViewProvider);

    expect(observer.history, [
      ProviderInitEvent(
        provider: numberProvider,
        notifier: numberNotifier,
        cause: ProviderInitCause.access,
        value: 0,
      ),
      ProviderInitEvent(
        provider: stringProvider,
        notifier: stringNotifier,
        cause: ProviderInitCause.access,
        value: 'a',
      ),
      ProviderInitEvent(
        provider: viewProvider,
        notifier: viewNotifier,
        cause: ProviderInitCause.access,
        value: _ComplexState(0, 'a'),
      ),
      ProviderInitEvent(
        provider: selectiveViewProvider,
        notifier: selectiveViewNotifier,
        cause: ProviderInitCause.access,
        value: 'a',
      ),
      ChangeEvent(
        notifier: numberNotifier,
        action: null,
        prev: 0,
        next: 1,
        rebuild: [viewNotifier],
      ),
      RebuildEvent(
        rebuildable: viewNotifier,
        causes: [
          ChangeEvent<int>(
            notifier: numberNotifier,
            action: null,
            prev: 0,
            next: 1,
            rebuild: [viewNotifier],
          ),
        ],
        prev: _ComplexState(0, 'a'),
        next: _ComplexState(1, 'a'),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: stringNotifier,
        action: null,
        prev: 'a',
        next: 'ab',
        rebuild: [viewNotifier],
      ),
      RebuildEvent(
        rebuildable: viewNotifier,
        causes: [
          ChangeEvent<String>(
            notifier: stringNotifier,
            action: null,
            prev: 'a',
            next: 'ab',
            rebuild: [viewNotifier],
          ),
        ],
        prev: _ComplexState(1, 'a'),
        next: _ComplexState(1, 'ab'),
        rebuild: [selectiveViewNotifier],
      ),
      RebuildEvent(
        rebuildable: selectiveViewNotifier,
        causes: [
          RebuildEvent<_ComplexState>(
            rebuildable: viewNotifier,
            causes: [
              ChangeEvent<String>(
                notifier: stringNotifier,
                action: null,
                prev: 'a',
                next: 'ab',
                rebuild: [viewNotifier],
              ),
            ],
            prev: _ComplexState(1, 'a'),
            next: _ComplexState(1, 'ab'),
            rebuild: [selectiveViewNotifier],
          ),
        ],
        prev: 'a',
        next: 'ab',
        rebuild: [],
      ),
    ]);
  });

  test('Should unwatch old provider', () async {
    final observer = RefenaHistoryObserver.only(
      startImmediately: false,
      rebuild: true,
    );
    final container = RefenaContainer(
      observers: [observer],
    );

    final switchProvider = StateProvider((ref) => true);
    final providerA = StateProvider((ref) => 10);
    final providerB = StateProvider((ref) => 20);
    int rebuildCount = 0;
    final viewProvider = ViewProvider((ref) {
      rebuildCount++;
      final b = ref.watch(switchProvider);
      if (b) {
        return ref.watch(providerA) + 1;
      } else {
        return ref.watch(providerB) + 1;
      }
    });

    final switchNotifier = container.anyNotifier(switchProvider);
    final notifierA = container.anyNotifier(providerA);
    final notifierB = container.anyNotifier(providerB);
    final viewNotifier = container.anyNotifier(viewProvider);

    // initial state
    expect(container.read(switchProvider), true);
    expect(container.read(providerA), 10);
    expect(container.read(providerB), 20);
    expect(container.read(viewProvider), 11);

    // Change state
    observer.start(clearHistory: true);
    container.notifier(providerA).setState((old) => old + 1);
    await skipAllMicrotasks();
    observer.stop();

    // Changing A should update view
    expect(container.read(switchProvider), true);
    expect(container.read(providerA), 11);
    expect(container.read(providerB), 20);
    expect(container.read(viewProvider), 12);
    expect(observer.history, [
      RebuildEvent(
        rebuildable: viewNotifier,
        causes: [
          ChangeEvent<int>(
            notifier: notifierA,
            action: null,
            prev: 10,
            next: 11,
            rebuild: [viewNotifier],
          ),
        ],
        prev: 11,
        next: 12,
        rebuild: [],
      ),
    ]);

    // Change watched provider
    observer.start(clearHistory: true);
    container.notifier(switchProvider).setState((_) => false);
    await skipAllMicrotasks();
    observer.stop();

    // Should watch B now
    expect(container.read(switchProvider), false);
    expect(container.read(providerA), 11);
    expect(container.read(providerB), 20);
    expect(container.read(viewProvider), 21);
    expect(observer.history, [
      RebuildEvent(
        rebuildable: viewNotifier,
        causes: [
          ChangeEvent<bool>(
            notifier: switchNotifier,
            action: null,
            prev: true,
            next: false,
            rebuild: [viewNotifier],
          ),
        ],
        prev: 12,
        next: 21,
        rebuild: [],
      ),
    ]);

    // Change state
    observer.start(clearHistory: true);
    rebuildCount = 0;
    container.notifier(providerB).setState((old) => old + 1);
    await skipAllMicrotasks();
    observer.stop();

    // Changing B should update view
    expect(container.read(switchProvider), false);
    expect(container.read(providerA), 11);
    expect(container.read(providerB), 21);
    expect(container.read(viewProvider), 22);
    expect(rebuildCount, 1);
    expect(observer.history, [
      RebuildEvent(
        rebuildable: viewNotifier,
        causes: [
          ChangeEvent<int>(
            notifier: notifierB,
            action: null,
            prev: 20,
            next: 21,
            rebuild: [viewNotifier],
          ),
        ],
        prev: 21,
        next: 22,
        rebuild: [],
      ),
    ]);

    // Change state
    observer.start(clearHistory: true);
    rebuildCount = 0;
    container.notifier(providerA).setState((old) => old + 1);
    await skipAllMicrotasks();
    observer.stop();

    // Changing A should not update view
    expect(container.read(switchProvider), false);
    expect(container.read(providerA), 12);
    expect(container.read(providerB), 21);
    expect(container.read(viewProvider), 22);
    expect(rebuildCount, 0);
    expect(observer.history, isEmpty);
  });
}

class _ComplexState {
  _ComplexState(this.number, this.string);

  final int number;
  final String string;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ComplexState &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          string == other.string;

  @override
  int get hashCode => number.hashCode ^ string.hashCode;

  _ComplexState copyWith({
    int? number,
    String? string,
  }) {
    return _ComplexState(
      number ?? this.number,
      string ?? this.string,
    );
  }
}
