import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

import '../util/skip_microtasks.dart';

void main() {
  test('Should emit events inside init', () async {
    final observer = RiverpieHistoryObserver.only(
      providerInit: true,
      change: true,
      actionDispatched: true,
    );
    final ref = RiverpieContainer(
      observer: observer,
    );

    final notifier = ref.notifier(_reduxProvider);
    await skipAllMicrotasks();

    // Check events
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: '_ReduxNotifier',
        debugOriginRef: notifier,
        notifier: notifier,
        action: _IncrementAction(),
      ),
      ProviderInitEvent(
        provider: _reduxProvider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: 0,
      ),
      ChangeEvent(
        notifier: notifier,
        action: _IncrementAction(),
        prev: 0,
        next: 1,
        rebuild: [],
      ),
    ]);
  });
}

final _reduxProvider = ReduxProvider<_ReduxNotifier, int>((ref) {
  return _ReduxNotifier();
});

class _ReduxNotifier extends ReduxNotifier<int> {
  @override
  int init() {
    dispatchAsync(_IncrementAction());
    return 0;
  }
}

class _IncrementAction extends AsyncReduxAction<_ReduxNotifier, int> {
  @override
  Future<int> reduce() async {
    return state + 1;
  }

  @override
  bool operator ==(Object other) => other is _IncrementAction;

  @override
  int get hashCode => 0;
}
