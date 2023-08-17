import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  test('Should change state', () {
    final notifier = _Counter();
    final provider = NotifierProvider<_Counter, int>((ref) => notifier);
    final observer = RiverpieHistoryObserver.all();
    final ref = RiverpieContainer(
      observer: observer,
    );

    expect(ref.read(provider), 123);

    ref.notifier(provider).emit(AddEvent(2));

    expect(ref.read(provider), 125);

    ref.notifier(provider).emit(SubtractEvent(5));

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

final counterProvider = NotifierProvider<_Counter, int>((ref) => _Counter());

class _Counter extends EventNotifier<int, CountEvent> {
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
