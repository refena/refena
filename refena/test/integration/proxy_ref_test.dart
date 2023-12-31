import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  late RefenaContainer container;
  final observer = RefenaHistoryObserver.only(
    actionDispatched: true,
  );

  setUp(() {
    observer.clear();
    container = RefenaContainer(
      observers: [observer],
    );
  });

  test('Observer should use label of observer', () {
    final historyObserver = RefenaHistoryObserver.only(
      message: true,
    );
    final customObserver = _CustomObserver();
    final container = RefenaContainer(
      observers: [
        historyObserver,
        customObserver,
      ],
    );

    container.message('Hello');

    expect(historyObserver.history, [
      MessageEvent(
        'Hello',
        container,
      ),
      MessageEvent(
        'Hi',
        customObserver,
      ),
    ]);
  });

  test('Should use container label', () {
    container.redux(_reduxProviderA).dispatch(_AddActionA(2));

    final notifier = container.redux(_reduxProviderA).notifier;
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RefenaContainer',
        debugOriginRef: container,
        notifier: notifier,
        action: _AddActionA(2),
      ),
    ]);
  });

  test('Should use given label', () {
    container
        .redux(_reduxProviderA)
        .dispatch(_AddActionA(2), debugOrigin: 'MyLabel');

    final notifier = container.redux(_reduxProviderA).notifier;
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'MyLabel',
        debugOriginRef: container,
        notifier: notifier,
        action: _AddActionA(2),
      ),
    ]);
  });

  test('Should use label of ReduxNotifier', () {
    final notifier = container.redux(_reduxProviderA).notifier;

    // ignore: invalid_use_of_protected_member
    notifier.dispatch(_AddActionA(2));

    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: '_ReduxA',
        debugOriginRef: notifier,
        notifier: notifier,
        action: _AddActionA(2),
      ),
    ]);
  });

  test('Should use label of another notifier', () {
    container.notifier(_anotherProvider).trigger();

    final notifier = container.redux(_reduxProviderA).notifier;
    final anotherNotifier = container.notifier(_anotherProvider);
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: '_AnotherNotifier',
        debugOriginRef: anotherNotifier,
        notifier: notifier,
        action: _AddActionA(5),
      ),
    ]);
  });

  test('Should use label of view', () {
    container.read(_viewProvider).trigger();

    final viewNotifier = container.anyNotifier(_viewProvider);
    final notifier = container.redux(_reduxProviderA).notifier;
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'ViewProvider<_Vm>',
        debugOriginRef: viewNotifier,
        notifier: notifier,
        action: _AddActionA(10),
      ),
    ]);
  });

  test('Should use label of the ReduxAction', () {
    final notifier = container.redux(_reduxProviderA).notifier;

    // ignore: invalid_use_of_protected_member
    notifier.dispatch(_DispatchActionA(2));

    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: '_ReduxA',
        debugOriginRef: notifier,
        notifier: notifier,
        action: _DispatchActionA(2),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_DispatchActionA',
        debugOriginRef: _DispatchActionA(2),
        notifier: notifier,
        action: _AddActionA(2),
      ),
    ]);
  });

  test('Should use same label when another notifier provided via DI', () {
    final notifierA = container.redux(_reduxProviderA).notifier;

    // ignore: invalid_use_of_protected_member
    notifierA.dispatch(_DispatchBAction());

    final notifierB = container.redux(_reduxProviderB).notifier;
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: '_ReduxA',
        debugOriginRef: notifierA,
        notifier: notifierA,
        action: _DispatchBAction(),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_DispatchBAction',
        debugOriginRef: _DispatchBAction(),
        notifier: notifierB,
        action: _AddActionB(12),
      ),
    ]);
  });
}

class _CustomObserver extends RefenaObserver {
  @override
  void handleEvent(RefenaEvent event) {
    // add if-statement to avoid infinite loop
    if (event is MessageEvent && event.origin != this) {
      ref.message('Hi');
    }
  }

  @override
  String get debugLabel => 'MyObserver';
}

final _reduxProviderA = ReduxProvider<_ReduxA, int>((ref) {
  return _ReduxA(ref.notifier(_reduxProviderB));
});

class _ReduxA extends ReduxNotifier<int> {
  _ReduxA(this.reduxB);

  final _ReduxB reduxB;

  @override
  int init() => 0;

  void trigger() {
    dispatch(_AddActionA(11));
  }
}

class _AddActionA extends ReduxAction<_ReduxA, int> {
  final int value;

  _AddActionA(this.value);

  @override
  int reduce() {
    return state + value;
  }

  @override
  bool operator ==(Object other) {
    return other is _AddActionA && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

class _DispatchActionA extends ReduxAction<_ReduxA, int> {
  final int value;

  _DispatchActionA(this.value);

  @override
  int reduce() {
    dispatch(_AddActionA(value));
    return state;
  }

  @override
  bool operator ==(Object other) {
    return other is _DispatchActionA && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

class _DispatchBAction extends ReduxAction<_ReduxA, int> {
  @override
  int reduce() => state;

  @override
  void after() {
    external(notifier.reduxB).dispatch(_AddActionB(12));
  }

  @override
  bool operator ==(Object other) {
    return other is _DispatchBAction;
  }

  @override
  int get hashCode => 0;
}

final _reduxProviderB = ReduxProvider<_ReduxB, int>((ref) => _ReduxB());

class _ReduxB extends ReduxNotifier<int> {
  @override
  int init() => 0;
}

class _AddActionB extends ReduxAction<_ReduxB, int> {
  final int value;

  _AddActionB(this.value);

  @override
  int reduce() {
    return state + value;
  }

  @override
  bool operator ==(Object other) {
    return other is _AddActionB && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

final _anotherProvider = NotifierProvider<_AnotherNotifier, int>((ref) {
  return _AnotherNotifier();
});

class _AnotherNotifier extends Notifier<int> {
  @override
  int init() => 0;

  void trigger() {
    ref.redux(_reduxProviderA).dispatch(_AddActionA(5));
  }
}

class _Vm {
  _Vm(this.trigger);

  final void Function() trigger;
}

final _viewProvider = ViewProvider<_Vm>((ref) {
  return _Vm(() {
    ref.redux(_reduxProviderA).dispatch(_AddActionA(10));
  });
});
