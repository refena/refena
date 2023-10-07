import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Should initialize with initial state', () {
    final container = RefenaContainer();

    final provider =
        ReduxProvider<_ReduxNotifier, int>((ref) => _ReduxNotifier());
    expect(container.read(provider), 100);
  });

  test('Should dispatch initial action', () {
    final observer = RefenaHistoryObserver.only(
      providerInit: true,
      actionDispatched: true,
      change: true,
    );
    final container = RefenaContainer(
      observers: [observer],
    );

    final provider = ReduxProvider<_ReduxNotifierWithInitialAction, int>(
        (ref) => _ReduxNotifierWithInitialAction());
    expect(container.read(provider), 210);

    // Check events
    final notifier = container.notifier(provider);
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: 200,
      ),
      ActionDispatchedEvent(
        debugOrigin: '_ReduxNotifierWithInitialAction',
        debugOriginRef: notifier,
        notifier: notifier,
        action: _InitialAction(),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _InitialAction(),
        prev: 200,
        next: 210,
        rebuild: [],
      ),
    ]);
  });

  test('Should dispatch async initial action', () async {
    final observer = RefenaHistoryObserver.only(
      providerInit: true,
      actionDispatched: true,
      change: true,
    );
    final container = RefenaContainer(
      observers: [observer],
    );

    final provider =
        ReduxProvider<_ReduxNotifierWithAsyncInitialAction, String>(
            (ref) => _ReduxNotifierWithAsyncInitialAction());
    expect(container.read(provider), 'A');

    await Future.delayed(const Duration(milliseconds: 50));

    expect(container.read(provider), 'AB');

    // Check events
    final notifier = container.notifier(provider);
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: 'A',
      ),
      ActionDispatchedEvent(
        debugOrigin: '_ReduxNotifierWithAsyncInitialAction',
        debugOriginRef: notifier,
        notifier: notifier,
        action: _AsyncInitialAction(),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _AsyncInitialAction(),
        prev: 'A',
        next: 'AB',
        rebuild: [],
      ),
    ]);
  });

  test('Should dispatch dispose action', () {
    final observer = RefenaHistoryObserver.only(
      providerInit: true,
      providerDispose: true,
      actionDispatched: true,
      change: true,
    );
    final container = RefenaContainer(
      observers: [observer],
    );

    bool onDisposeCalled = false;
    final provider = ReduxProvider<_ReduxNotifierWithDisposeAction, int>(
      (ref) => _ReduxNotifierWithDisposeAction(() => onDisposeCalled = true),
    );

    final notifier = container.notifier(provider);
    expect(container.read(provider), 300);
    expect(onDisposeCalled, false);

    container.dispose(provider);
    expect(onDisposeCalled, true);

    // Check events
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: 300,
      ),
      ActionDispatchedEvent(
        debugOrigin: '_ReduxNotifierWithDisposeAction',
        debugOriginRef: notifier,
        notifier: notifier,
        action: _DisposeAction(() {}),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _DisposeAction(() {}),
        prev: 300,
        next: 310,
        rebuild: [],
      ),
      ProviderDisposeEvent(
        provider: provider,
        notifier: notifier,
      ),
    ]);
  });
}

class _ReduxNotifier extends ReduxNotifier<int> {
  @override
  int init() => 100;
}

class _ReduxNotifierWithInitialAction extends ReduxNotifier<int> {
  @override
  int init() => 200;

  @override
  get initialAction => _InitialAction();
}

class _InitialAction extends ReduxAction<_ReduxNotifierWithInitialAction, int> {
  @override
  int reduce() {
    return state + 10;
  }

  @override
  bool operator ==(Object other) {
    return other is _InitialAction;
  }

  @override
  int get hashCode => 0;
}

class _ReduxNotifierWithAsyncInitialAction extends ReduxNotifier<String> {
  @override
  String init() => 'A';

  @override
  get initialAction => _AsyncInitialAction();
}

class _AsyncInitialAction
    extends AsyncReduxAction<_ReduxNotifierWithAsyncInitialAction, String> {
  @override
  Future<String> reduce() async {
    await skipAllMicrotasks();
    return '${state}B';
  }

  @override
  bool operator ==(Object other) {
    return other is _AsyncInitialAction;
  }

  @override
  int get hashCode => 0;
}

class _ReduxNotifierWithDisposeAction extends ReduxNotifier<int> {
  final void Function() onDispose;

  _ReduxNotifierWithDisposeAction(this.onDispose);

  @override
  int init() => 300;

  @override
  get disposeAction => _DisposeAction(onDispose);
}

class _DisposeAction extends ReduxAction<_ReduxNotifierWithDisposeAction, int> {
  final void Function() onDispose;

  _DisposeAction(this.onDispose);

  @override
  int reduce() {
    onDispose();
    return state + 10;
  }

  @override
  bool operator ==(Object other) {
    return other is _DisposeAction;
  }

  @override
  int get hashCode => 0;
}
