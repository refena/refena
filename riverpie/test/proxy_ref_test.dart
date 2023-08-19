import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  late RiverpieContainer ref;
  final observer = RiverpieHistoryObserver(HistoryObserverConfig(
    saveChangeEvents: false,
    saveEventEmittedEvents: true,
  ));

  setUp(() {
    observer.clear();
    ref = RiverpieContainer(
      observer: observer,
    );
  });

  test('Should use container label', () {
    ref.redux(_reduxProviderA).emit(AddEvent(2));

    final notifier = ref.redux(_reduxProviderA).notifier;
    expect(observer.history, [
      EventEmittedEvent(
        debugOrigin: 'RiverpieContainer',
        notifier: notifier,
        event: AddEvent(2),
      ),
    ]);
  });

  test('Should use given label', () {
    ref.redux(_reduxProviderA).emit(AddEvent(2), debugOrigin: 'MyLabel');

    final notifier = ref.redux(_reduxProviderA).notifier;
    expect(observer.history, [
      EventEmittedEvent(
        debugOrigin: 'MyLabel',
        notifier: notifier,
        event: AddEvent(2),
      ),
    ]);
  });

  test('Should use label of ReduxNotifier', () {
    final notifier = ref.redux(_reduxProviderA).notifier;
    notifier.emit(AddEvent(2));

    expect(observer.history, [
      EventEmittedEvent(
        debugOrigin: '_ReduxA',
        notifier: notifier,
        event: AddEvent(2),
      ),
    ]);
  });

  test('Should use label of another notifier', () {
    ref.notifier(_anotherProvider).trigger();

    final notifier = ref.redux(_reduxProviderA).notifier;
    expect(observer.history, [
      EventEmittedEvent(
        debugOrigin: '_AnotherNotifier',
        notifier: notifier,
        event: AddEvent(5),
      ),
    ]);
  });

  test('Should use label of view', () {
    ref.read(_viewProvider).trigger();

    final notifier = ref.redux(_reduxProviderA).notifier;
    expect(observer.history, [
      EventEmittedEvent(
        debugOrigin: 'ViewProvider<_Vm>',
        notifier: notifier,
        event: AddEvent(10),
      ),
    ]);
  });

  test('Should use same label when another notifier provided via DI', () {
    final notifierA = ref.redux(_reduxProviderA).notifier;
    final notifierB = ref.redux(_reduxProviderB).notifier;
    notifierA.emitEventOfB();
    expect(observer.history, [
      EventEmittedEvent(
        debugOrigin: '_ReduxA',
        notifier: notifierB,
        event: AddEvent(12),
      ),
    ]);
  });
}

final _reduxProviderA = ReduxProvider<_ReduxA, int, _CountEvent>((ref) {
  return _ReduxA(ref.redux(_reduxProviderB));
});

class _ReduxA extends ReduxNotifier<int, _CountEvent> {
  _ReduxA(this._reduxB);

  final Emittable<_ReduxB, _CountEvent> _reduxB;

  @override
  int init() => 0;

  @override
  int reduce(_CountEvent event) {
    return switch (event) {
      AddEvent() => state + event.value,
      SubtractEvent() => state - event.value,
    };
  }

  void trigger() {
    emit(AddEvent(11));
  }

  void emitEventOfB() {
    _reduxB.emit(AddEvent(12));
  }
}

final _reduxProviderB =
    ReduxProvider<_ReduxB, int, _CountEvent>((ref) => _ReduxB());

class _ReduxB extends ReduxNotifier<int, _CountEvent> {
  @override
  int init() => 0;

  @override
  int reduce(_CountEvent event) {
    return switch (event) {
      AddEvent() => state + event.value,
      SubtractEvent() => state - event.value,
    };
  }
}

sealed class _CountEvent {
  _CountEvent(this.value);

  final int value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _CountEvent &&
            runtimeType == other.runtimeType &&
            value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class AddEvent extends _CountEvent {
  AddEvent(super.value);
}

class SubtractEvent extends _CountEvent {
  SubtractEvent(super.value);
}

final _anotherProvider = NotifierProvider<_AnotherNotifier, int>((ref) {
  return _AnotherNotifier();
});

class _AnotherNotifier extends Notifier<int> {
  @override
  int init() => 0;

  void trigger() {
    ref.redux(_reduxProviderA).emit(AddEvent(5));
  }
}

class _Vm {
  _Vm(this.trigger);

  final void Function() trigger;
}

final _viewProvider = ViewProvider<_Vm>((ref) {
  return _Vm(() {
    ref.redux(_reduxProviderA).emit(AddEvent(10));
  });
});
