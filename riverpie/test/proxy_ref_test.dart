import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  late RiverpieContainer ref;
  final observer = RiverpieHistoryObserver(HistoryObserverConfig(
    saveChangeEvents: false,
    saveActionDispatchedEvents: true,
  ));

  setUp(() {
    observer.clear();
    ref = RiverpieContainer(
      observer: observer,
    );
  });

  test('Should use container label', () {
    ref.redux(_reduxProviderA).dispatch(_AddActionA(2));

    final notifier = ref.redux(_reduxProviderA).notifier;
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RiverpieContainer',
        notifier: notifier,
        action: _AddActionA(2),
      ),
    ]);
  });

  test('Should use given label', () {
    ref.redux(_reduxProviderA).dispatch(_AddActionA(2), debugOrigin: 'MyLabel');

    final notifier = ref.redux(_reduxProviderA).notifier;
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'MyLabel',
        notifier: notifier,
        action: _AddActionA(2),
      ),
    ]);
  });

  test('Should use label of ReduxNotifier', () {
    final notifier = ref.redux(_reduxProviderA).notifier;
    notifier.dispatch(_AddActionA(2));

    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: '_ReduxA',
        notifier: notifier,
        action: _AddActionA(2),
      ),
    ]);
  });

  test('Should use label of another notifier', () {
    ref.notifier(_anotherProvider).trigger();

    final notifier = ref.redux(_reduxProviderA).notifier;
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: '_AnotherNotifier',
        notifier: notifier,
        action: _AddActionA(5),
      ),
    ]);
  });

  test('Should use label of view', () {
    ref.read(_viewProvider).trigger();

    final notifier = ref.redux(_reduxProviderA).notifier;
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'ViewProvider<_Vm>',
        notifier: notifier,
        action: _AddActionA(10),
      ),
    ]);
  });

  test('Should use same label when another notifier provided via DI', () {
    final notifierA = ref.redux(_reduxProviderA).notifier;
    final notifierB = ref.redux(_reduxProviderB).notifier;
    notifierA.dispatch(_DispatchBAction());
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: '_ReduxA',
        notifier: notifierA,
        action: _DispatchBAction(),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_ReduxA',
        notifier: notifierB,
        action: _AddActionB(12),
      ),
    ]);
  });
}

final _reduxProviderA = ReduxProvider<_ReduxA, int>((ref) {
  return _ReduxA(ref.redux(_reduxProviderB));
});

class _ReduxA extends ReduxNotifier<int> {
  _ReduxA(this.reduxB);

  final Dispatcher<_ReduxB, int> reduxB;

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

class _DispatchBAction extends ReduxAction<_ReduxA, int> {
  @override
  int reduce() {
    notifier.reduxB.dispatch(_AddActionB(12));
    return state;
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
