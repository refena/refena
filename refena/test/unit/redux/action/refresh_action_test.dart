import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../../util/skip_microtasks.dart';

void main() {
  late RefenaHistoryObserver observer;

  setUp(() {
    observer = RefenaHistoryObserver.only(
      actionDispatched: true,
      change: true,
    );
  });

  test('Should correctly set the new state', () async {
    final ref = RefenaContainer(
      observers: [observer],
    );

    final provider = ReduxProvider<_ReduxNotifier, AsyncValue<int>>(
      (ref) => _ReduxNotifier(),
    );

    await ref.redux(provider).dispatchAsync(_RefreshAction(2));

    expect(ref.read(provider), AsyncValue.data(2));

    // Check events
    final notifier = ref.notifier(provider);
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RefenaContainer',
        debugOriginRef: ref,
        notifier: notifier,
        action: _RefreshAction(2),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_RefreshAction',
        debugOriginRef: _RefreshAction(2),
        notifier: notifier,
        action: RefreshSetLoadingAction<_ReduxNotifier, int>(0),
      ),
      ChangeEvent(
        notifier: ref.notifier(provider),
        action: RefreshSetLoadingAction<_ReduxNotifier, int>(0),
        prev: AsyncValue.data(0),
        next: AsyncValue<int>.loading(0),
        rebuild: [],
      ),
      ChangeEvent(
        notifier: ref.notifier(provider),
        action: _RefreshAction(2),
        prev: AsyncValue<int>.loading(0),
        next: AsyncValue.data(2),
        rebuild: [],
      ),
    ]);
  });

  test('Should correctly set error state', () async {
    final ref = RefenaContainer(
      observers: [observer],
    );

    final provider = ReduxProvider<_ReduxNotifier, AsyncValue<int>>(
      (ref) => _ReduxNotifier(),
    );

    await expectLater(
      () => ref.redux(provider).dispatchAsync(_RefreshErrorAction()),
      throwsA('error'),
    );

    expect(
      ref.read(provider),
      AsyncValue<int>.error('error', StackTrace.fromString(''), 0),
    );

    // Check events
    final notifier = ref.notifier(provider);
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RefenaContainer',
        debugOriginRef: ref,
        notifier: notifier,
        action: _RefreshErrorAction(),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_RefreshErrorAction',
        debugOriginRef: _RefreshErrorAction(),
        notifier: notifier,
        action: RefreshSetLoadingAction<_ReduxNotifier, int>(0),
      ),
      ChangeEvent(
        notifier: ref.notifier(provider),
        action: RefreshSetLoadingAction<_ReduxNotifier, int>(0),
        prev: AsyncValue.data(0),
        next: AsyncValue<int>.loading(0),
        rebuild: [],
      ),
      ActionDispatchedEvent(
        debugOrigin: '_RefreshErrorAction',
        debugOriginRef: _RefreshErrorAction(),
        notifier: notifier,
        action: RefreshSetErrorAction<_ReduxNotifier, int>(
          error: 'error',
          stackTrace: StackTrace.fromString(''),
          previousData: 0,
        ),
      ),
      ChangeEvent(
        notifier: ref.notifier(provider),
        action: RefreshSetErrorAction<_ReduxNotifier, int>(
          error: 'error',
          stackTrace: StackTrace.fromString(''),
          previousData: 0,
        ),
        prev: AsyncValue<int>.loading(0),
        next: AsyncValue<int>.error('error', StackTrace.fromString(''), 0),
        rebuild: [],
      ),
    ]);
  });

  test('Should correctly keep previous state', () async {
    final ref = RefenaContainer(
      observers: [observer],
    );

    final provider = ReduxProvider<_ReduxNotifier, AsyncValue<int>>(
      (ref) => _ReduxNotifier(),
    );

    expect(ref.read(provider).data, 0);

    await ref.redux(provider).dispatchAsync(_RefreshAction(2));
    expect(ref.read(provider), AsyncValue.data(2));
    expect(ref.read(provider).data, 2);

    var future = ref.redux(provider).dispatchAsync(_RefreshAction(3));
    await skipAllMicrotasks();
    expect(ref.read(provider), AsyncValue.loading(2));
    expect(ref.read(provider).data, 2);
    await future;
    expect(ref.read(provider), AsyncValue.data(3));
    expect(ref.read(provider).data, 3);

    future = ref.redux(provider).dispatchAsync(_RefreshErrorAction());
    await skipAllMicrotasks();
    expect(ref.read(provider), AsyncValue.loading(3));
    expect(ref.read(provider).data, 3);
    await expectLater(future, throwsA('error'));
    expect(
      ref.read(provider),
      AsyncValue<int>.error('error', StackTrace.fromString(''), 3),
    );
    expect(ref.read(provider).data, 3);
  });
}

class _ReduxNotifier extends ReduxNotifier<AsyncValue<int>> {
  @override
  AsyncValue<int> init() => AsyncValue.data(0);
}

class _RefreshAction extends RefreshAction<_ReduxNotifier, int> {
  final int newValue;

  _RefreshAction(this.newValue);

  @override
  Future<int> refresh() async {
    await skipAllMicrotasks();
    return newValue;
  }

  @override
  bool operator ==(Object other) {
    return other is _RefreshAction && other.newValue == newValue;
  }

  @override
  int get hashCode => newValue.hashCode;
}

class _RefreshErrorAction extends RefreshAction<_ReduxNotifier, int> {
  @override
  Future<int> refresh() async {
    await skipAllMicrotasks();
    throw 'error';
  }

  @override
  bool operator ==(Object other) {
    return other is _RefreshErrorAction;
  }

  @override
  int get hashCode => 0;
}
