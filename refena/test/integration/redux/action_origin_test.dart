import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  late RefenaHistoryObserver observer;

  setUp(() {
    observer = RefenaHistoryObserver.only(
      actionDispatched: true,
    );
  });

  test('Should track origin action by default', () {
    final ref = RefenaContainer(
      observers: [observer],
    );

    ref.redux(_counterProvider).dispatch(_ParentAction(ignoreOrigin: false));

    final notifier = ref.notifier(_counterProvider);
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RefenaContainer',
        debugOriginRef: ref,
        notifier: notifier,
        action: _ParentAction(ignoreOrigin: false),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_ParentAction',
        debugOriginRef: _ParentAction(ignoreOrigin: false),
        notifier: notifier,
        action: _ChildAction(1),
      ),
    ]);
  });

  test('Should track origin action by default (async)', () async {
    final ref = RefenaContainer(
      observers: [observer],
    );

    await ref
        .redux(_counterProvider)
        .dispatchAsync(_ParentActionAsync(ignoreOrigin: false));

    final notifier = ref.notifier(_counterProvider);
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RefenaContainer',
        debugOriginRef: ref,
        notifier: notifier,
        action: _ParentActionAsync(ignoreOrigin: false),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_ParentActionAsync',
        debugOriginRef: _ParentActionAsync(ignoreOrigin: false),
        notifier: notifier,
        action: _ChildActionAsync(1),
      ),
    ]);
  });

  test('Should not track origin action', () {
    final ref = RefenaContainer(
      observers: [observer],
    );

    ref.redux(_counterProvider).dispatch(_ParentAction(ignoreOrigin: true));

    final notifier = ref.notifier(_counterProvider);
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RefenaContainer',
        debugOriginRef: ref,
        notifier: notifier,
        action: _ParentAction(ignoreOrigin: true),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_ParentAction',
        debugOriginRef: notifier,
        notifier: notifier,
        action: _ChildActionNoOrigin(1),
      ),
    ]);
  });

  test('Should not track origin action (async)', () async {
    final ref = RefenaContainer(
      observers: [observer],
    );

    await ref
        .redux(_counterProvider)
        .dispatchAsync(_ParentActionAsync(ignoreOrigin: true));

    final notifier = ref.notifier(_counterProvider);
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RefenaContainer',
        debugOriginRef: ref,
        notifier: notifier,
        action: _ParentActionAsync(ignoreOrigin: true),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_ParentActionAsync',
        debugOriginRef: notifier,
        notifier: notifier,
        action: _ChildActionNoOriginAsync(1),
      ),
    ]);
  });
}

final _counterProvider = ReduxProvider<_Counter, int>((ref) => _Counter());

class _Counter extends ReduxNotifier<int> {
  @override
  int init() => 123;
}

class _ParentAction extends ReduxAction<_Counter, int> {
  final bool ignoreOrigin;

  _ParentAction({required this.ignoreOrigin});

  @override
  int reduce() {
    if (ignoreOrigin) {
      return dispatch(_ChildActionNoOrigin(1));
    } else {
      return dispatch(_ChildAction(1));
    }
  }

  @override
  bool operator ==(Object other) {
    return other is _ParentAction;
  }

  @override
  int get hashCode;
}

class _ChildAction extends ReduxAction<_Counter, int> {
  final int amount;

  _ChildAction(this.amount);

  @override
  int reduce() {
    return state + amount;
  }

  @override
  bool operator ==(Object other) {
    return other is _ChildAction && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;
}

class _ChildActionNoOrigin extends ReduxAction<_Counter, int> {
  final int amount;

  _ChildActionNoOrigin(this.amount);

  @override
  bool get trackOrigin => false;

  @override
  int reduce() {
    return state + amount;
  }

  @override
  bool operator ==(Object other) {
    return other is _ChildActionNoOrigin && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;
}

class _ParentActionAsync extends AsyncReduxAction<_Counter, int> {
  final bool ignoreOrigin;

  _ParentActionAsync({required this.ignoreOrigin});

  @override
  Future<int> reduce() {
    if (ignoreOrigin) {
      return dispatchAsync(_ChildActionNoOriginAsync(1));
    } else {
      return dispatchAsync(_ChildActionAsync(1));
    }
  }

  @override
  bool operator ==(Object other) {
    return other is _ParentActionAsync;
  }

  @override
  int get hashCode;
}

class _ChildActionAsync extends AsyncReduxAction<_Counter, int> {
  final int amount;

  _ChildActionAsync(this.amount);

  @override
  Future<int> reduce() async {
    return state + amount;
  }

  @override
  bool operator ==(Object other) {
    return other is _ChildActionAsync && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;
}

class _ChildActionNoOriginAsync extends AsyncReduxAction<_Counter, int> {
  final int amount;

  _ChildActionNoOriginAsync(this.amount);

  @override
  bool get trackOrigin => false;

  @override
  Future<int> reduce() async {
    return state + amount;
  }

  @override
  bool operator ==(Object other) {
    return other is _ChildActionNoOriginAsync && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;
}
