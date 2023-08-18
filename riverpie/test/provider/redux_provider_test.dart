import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  test('Should change state without container', () {
    final notifier = _Counter();
    expect(notifier.getState(), 123);
    notifier.emit(AddEvent(10));
    expect(notifier.getState(), 133);
  });

  test('Should change state', () {
    final notifier = _Counter();
    final provider =
        ReduxProvider<_Counter, int, CountEvent>((ref) => notifier);
    final observer = RiverpieHistoryObserver.all();
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(provider), 123);

    ref.redux(provider).notifier.emit(AddEvent(2));

    expect(ref.read(provider), 125);

    ref.redux(provider).emit(SubtractEvent(5));

    expect(ref.read(provider), 120);

    // Check events
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: 123,
      ),
      EventEmittedEvent(
        debugOwnerLabel: '_Counter',
        notifier: notifier,
        event: AddEvent(2),
      ),
      ChangeEvent(
        notifier: notifier,
        event: AddEvent(2),
        prev: 123,
        next: 125,
        rebuild: [],
      ),
      EventEmittedEvent(
        debugOwnerLabel: 'RiverpieContainer',
        notifier: notifier,
        event: SubtractEvent(5),
      ),
      ChangeEvent(
        notifier: notifier,
        event: SubtractEvent(5),
        prev: 125,
        next: 120,
        rebuild: [],
      ),
    ]);
  });

  test('Should await event', () async {
    final notifier = _AsyncCounter();
    final provider =
        ReduxProvider<_AsyncCounter, int, CountEvent>((ref) => notifier);
    final observer = RiverpieHistoryObserver();
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(provider), 123);

    ref.redux(provider).emit(SubtractEvent(5));
    expect(ref.read(provider), 123);
    ref.redux(provider).emit(AddEvent(2));
    expect(ref.read(provider), 123);

    await Future.delayed(Duration(milliseconds: 100));
    expect(ref.read(provider), 120);

    await ref.redux(provider).notifier.emit(SubtractEvent(5));
    expect(ref.read(provider), 115);

    await ref.redux(provider).emit(SubtractEvent(5));
    expect(ref.read(provider), 110);

    // Check events
    expect(observer.history, [
      EventEmittedEvent(
        debugOwnerLabel: 'RiverpieContainer',
        notifier: notifier,
        event: SubtractEvent(5),
      ),
      EventEmittedEvent(
        debugOwnerLabel: 'RiverpieContainer',
        notifier: notifier,
        event: AddEvent(2),
      ),
      ChangeEvent(
        notifier: notifier,
        event: AddEvent(2),
        prev: 123,
        next: 125,
        rebuild: [],
      ),
      ChangeEvent(
        notifier: notifier,
        event: SubtractEvent(5),
        prev: 125,
        next: 120,
        rebuild: [],
      ),
      EventEmittedEvent(
        debugOwnerLabel: '_AsyncCounter',
        notifier: notifier,
        event: SubtractEvent(5),
      ),
      ChangeEvent(
        notifier: notifier,
        event: SubtractEvent(5),
        prev: 120,
        next: 115,
        rebuild: [],
      ),
      EventEmittedEvent(
        debugOwnerLabel: 'RiverpieContainer',
        notifier: notifier,
        event: SubtractEvent(5),
      ),
      ChangeEvent(
        notifier: notifier,
        event: SubtractEvent(5),
        prev: 115,
        next: 110,
        rebuild: [],
      ),
    ]);
  });
}

sealed class CountEvent {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountEvent && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class AddEvent extends CountEvent {
  final int addedAmount;

  AddEvent(this.addedAmount);
}

final class SubtractEvent extends CountEvent {
  final int subtractedAmount;

  SubtractEvent(this.subtractedAmount);
}

final counterProvider =
    ReduxProvider<_Counter, int, CountEvent>((ref) => _Counter());

class _Counter extends ReduxNotifier<int, CountEvent> {
  @override
  int init() => 123;

  @override
  int reduce(CountEvent event) {
    return switch (event) {
      AddEvent() => state + event.addedAmount,
      SubtractEvent() => _handleSubtractEvent(event),
    };
  }

  int _handleSubtractEvent(SubtractEvent event) {
    return state - event.subtractedAmount;
  }
}

final asyncCounterProvider =
    ReduxProvider<_AsyncCounter, int, CountEvent>((ref) => _AsyncCounter());

class _AsyncCounter extends ReduxNotifier<int, CountEvent> {
  @override
  int init() => 123;

  @override
  Future<int> reduce(CountEvent event) async {
    return switch (event) {
      AddEvent() => _handleAddEvent(event),
      SubtractEvent() => _handleSubtractEvent(event),
    };
  }

  Future<int> _handleAddEvent(AddEvent event) async {
    return state + event.addedAmount;
  }

  Future<int> _handleSubtractEvent(SubtractEvent event) async {
    await Future.delayed(Duration(milliseconds: 50));
    return state - event.subtractedAmount;
  }
}
