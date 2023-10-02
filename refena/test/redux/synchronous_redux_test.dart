import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  test('Should change state', () {
    final notifier = _Counter();
    final provider = ReduxProvider<_Counter, int>((ref) => notifier);
    final observer = RefenaHistoryObserver.only(
      providerInit: true,
      change: true,
      actionDispatched: true,
    );
    final ref = RefenaContainer(
      observer: observer,
    );

    expect(ref.read(provider), 123);

    // ignore: invalid_use_of_protected_member
    final addResult = ref.redux(provider).notifier.dispatch(_AddAction(2));
    expect(addResult, 125);
    expect(ref.read(provider), 125);

    final subtractResult = ref.redux(provider).dispatch(_SubtractAction(5));
    expect(subtractResult, 120);
    expect(ref.read(provider), 120);

    // Check events
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: 123,
      ),
      ActionDispatchedEvent(
        debugOrigin: '_Counter',
        debugOriginRef: notifier,
        notifier: notifier,
        action: _AddAction(2),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _AddAction(2),
        prev: 123,
        next: 125,
        rebuild: [],
      ),
      ActionDispatchedEvent(
        debugOrigin: 'RefenaContainer',
        debugOriginRef: ref,
        notifier: notifier,
        action: _SubtractAction(5),
      ),
      ChangeEvent(
        notifier: notifier,
        action: _SubtractAction(5),
        prev: 125,
        next: 120,
        rebuild: [],
      ),
    ]);
  });
}

final counterProvider = ReduxProvider<_Counter, int>((ref) => _Counter());

class _Counter extends ReduxNotifier<int> {
  @override
  int init() => 123;
}

class _AddAction extends ReduxAction<_Counter, int> {
  final int amount;

  _AddAction(this.amount);

  @override
  int reduce() {
    return state + amount;
  }

  @override
  bool operator ==(Object other) {
    return other is _AddAction && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;
}

class _SubtractAction extends ReduxAction<_Counter, int> {
  final int amount;

  _SubtractAction(this.amount);

  @override
  int reduce() {
    return state - amount;
  }

  @override
  bool operator ==(Object other) {
    return other is _SubtractAction && other.amount == amount;
  }

  @override
  int get hashCode => amount.hashCode;
}
