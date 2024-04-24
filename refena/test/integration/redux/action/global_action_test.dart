import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  late RefenaHistoryObserver observer;

  setUp(() {
    observer = RefenaHistoryObserver.only(
      actionDispatched: true,
    );
  });

  group(GlobalAction, () {
    test('Should dispatch', () {
      final ref = RefenaContainer(
        observers: [observer],
      );

      expect(ref.read(_stateProvider), 0);

      ref.global.dispatch(_MyGlobalAction());

      expect(ref.read(_stateProvider), 1);

      // Check events
      expect(observer.history.length, 1);
      expect(
        observer.history.first,
        ActionDispatchedEvent(
          debugOrigin: 'RefenaContainer',
          debugOriginRef: ref,
          notifier: ref.notifier(globalReduxProvider),
          action: _MyGlobalAction(),
        ),
      );
    });

    test('Should dispatch nested action', () {
      final ref = RefenaContainer(
        observers: [observer],
      );

      expect(ref.read(_stateProvider), 0);

      ref.global.dispatch(_MyNestedGlobalAction());

      expect(ref.read(_stateProvider), 1);

      // Check events
      final notifier = ref.notifier(globalReduxProvider);
      expect(observer.history.length, 2);
      expect(
        observer.history.first,
        ActionDispatchedEvent(
          debugOrigin: 'RefenaContainer',
          debugOriginRef: ref,
          notifier: notifier,
          action: _MyNestedGlobalAction(),
        ),
      );
      expect(
        observer.history.last,
        ActionDispatchedEvent(
          debugOrigin: '_MyNestedGlobalAction',
          debugOriginRef: _MyNestedGlobalAction(),
          notifier: notifier,
          action: _MyGlobalAction(),
        ),
      );
    });
  });

  group(AsyncGlobalAction, () {
    test('Should dispatch', () async {
      final ref = RefenaContainer(
        observers: [observer],
      );

      expect(ref.read(_stateProvider), 0);

      await ref.global.dispatchAsync(_MyAsyncGlobalAction());

      expect(ref.read(_stateProvider), 1);

      // Check events
      expect(observer.history.length, 1);
      expect(
        observer.history.first,
        ActionDispatchedEvent(
          debugOrigin: 'RefenaContainer',
          debugOriginRef: ref,
          notifier: ref.notifier(globalReduxProvider),
          action: _MyAsyncGlobalAction(),
        ),
      );
    });
  });

  group(GlobalActionWithResult, () {
    test('Should dispatch', () {
      final ref = RefenaContainer(
        observers: [observer],
      );

      expect(ref.read(_stateProvider), 0);

      final result = ref.global.dispatch(_MyGlobalActionWithResult());

      expect(ref.read(_stateProvider), 1);
      expect(result, 1);

      // Check events
      expect(observer.history.length, 1);
      expect(
        observer.history.first,
        ActionDispatchedEvent(
          debugOrigin: 'RefenaContainer',
          debugOriginRef: ref,
          notifier: ref.notifier(globalReduxProvider),
          action: _MyGlobalActionWithResult(),
        ),
      );
    });
  });

  group(AsyncGlobalActionWithResult, () {
    test('Should dispatch', () async {
      final ref = RefenaContainer(
        observers: [observer],
      );

      expect(ref.read(_stateProvider), 0);

      final result =
          await ref.global.dispatchAsync(_MyAsyncGlobalActionWithResult());

      expect(ref.read(_stateProvider), 1);
      expect(result, 1);

      // Check events
      expect(observer.history.length, 1);
      expect(
        observer.history.first,
        ActionDispatchedEvent(
          debugOrigin: 'RefenaContainer',
          debugOriginRef: ref,
          notifier: ref.notifier(globalReduxProvider),
          action: _MyAsyncGlobalActionWithResult(),
        ),
      );
    });
  });
}

final _stateProvider = StateProvider((ref) => 0);

class _MyGlobalAction extends GlobalAction {
  @override
  void reduce() {
    ref.notifier(_stateProvider).setState((old) => old + 1);
  }

  @override
  bool operator ==(Object other) => other is _MyGlobalAction;

  @override
  int get hashCode => 0;
}

class _MyAsyncGlobalAction extends AsyncGlobalAction {
  @override
  Future<void> reduce() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    ref.notifier(_stateProvider).setState((old) => old + 1);
  }

  @override
  bool operator ==(Object other) => other is _MyAsyncGlobalAction;

  @override
  int get hashCode => 0;
}

class _MyGlobalActionWithResult extends GlobalActionWithResult<int> {
  @override
  int reduce() {
    ref.notifier(_stateProvider).setState((old) => old + 1);
    return ref.read(_stateProvider);
  }

  @override
  bool operator ==(Object other) => other is _MyGlobalActionWithResult;

  @override
  int get hashCode => 0;
}

class _MyAsyncGlobalActionWithResult extends AsyncGlobalActionWithResult<int> {
  @override
  Future<int> reduce() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    ref.notifier(_stateProvider).setState((old) => old + 1);
    return ref.read(_stateProvider);
  }

  @override
  bool operator ==(Object other) => other is _MyAsyncGlobalActionWithResult;

  @override
  int get hashCode => 0;
}

class _MyNestedGlobalAction extends GlobalAction {
  @override
  void reduce() {}

  @override
  void after() {
    ref.global.dispatch(_MyGlobalAction());
  }

  @override
  bool operator ==(Object other) => other is _MyNestedGlobalAction;

  @override
  int get hashCode => 0;
}
