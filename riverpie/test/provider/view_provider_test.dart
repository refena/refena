import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

import '../util/skip_microtasks.dart';

void main() {
  test('Single provider test', () {
    final provider = ViewProvider((ref) => 123);
    final observer = RiverpieHistoryObserver.all();
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
    final observer = RiverpieHistoryObserver.all();
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
        event: null,
        prev: 0,
        next: 1,
        rebuild: [viewNotifier],
      ),
      ChangeEvent(
        notifier: viewNotifier,
        event: null,
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

    final observer = RiverpieHistoryObserver.all();
    final ref = RiverpieContainer(
      observer: observer,
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
      ListenerAddedEvent(
        notifier: numberNotifier,
        rebuildable: viewNotifier,
      ),
      ProviderInitEvent(
        provider: stringProvider,
        notifier: stringNotifier,
        cause: ProviderInitCause.access,
        value: 'a',
      ),
      ListenerAddedEvent(
        notifier: stringNotifier,
        rebuildable: viewNotifier,
      ),
      ProviderInitEvent(
        provider: viewProvider,
        notifier: viewNotifier,
        cause: ProviderInitCause.access,
        value: _ComplexState(0, 'a'),
      ),
      ListenerAddedEvent(
        notifier: viewNotifier,
        rebuildable: selectiveViewNotifier,
      ),
      ProviderInitEvent(
        provider: selectiveViewProvider,
        notifier: selectiveViewNotifier,
        cause: ProviderInitCause.access,
        value: 'a',
      ),
      ChangeEvent(
        notifier: numberNotifier,
        event: null,
        prev: 0,
        next: 1,
        rebuild: [viewNotifier],
      ),
      ChangeEvent(
        notifier: viewNotifier,
        event: null,
        prev: _ComplexState(0, 'a'),
        next: _ComplexState(1, 'a'),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: stringNotifier,
        event: null,
        prev: 'a',
        next: 'ab',
        rebuild: [viewNotifier],
      ),
      ChangeEvent(
        notifier: viewNotifier,
        event: null,
        prev: _ComplexState(1, 'a'),
        next: _ComplexState(1, 'ab'),
        rebuild: [selectiveViewNotifier],
      ),
      ChangeEvent(
        notifier: selectiveViewNotifier,
        event: null,
        prev: 'a',
        next: 'ab',
        rebuild: [],
      ),
    ]);
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
