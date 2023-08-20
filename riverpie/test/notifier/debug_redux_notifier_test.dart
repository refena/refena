import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  test('Should change state', () {
    final notifier = ReduxNotifier.test(
      notifier: _Counter(),
    );

    expect(notifier.state, 50);

    notifier.emit(_ChangeEvent.increment);
    expect(notifier.state, 51);

    notifier.setState(5);
    expect(notifier.state, 5);

    notifier.emit(_ChangeEvent.decrement);
    expect(notifier.state, 4);
  });

  test('Should set initial state', () {
    final notifier = ReduxNotifier.test(
      notifier: _Counter(),
      initialState: 11,
    );

    expect(notifier.state, 11);

    notifier.emit(_ChangeEvent.increment);
    expect(notifier.state, 12);
  });
}

enum _ChangeEvent { increment, decrement }

class _Counter extends ReduxNotifier<int, _ChangeEvent> {
  @override
  int init() => 50;

  @override
  int reduce(_ChangeEvent event) {
    return switch (event) {
      _ChangeEvent.increment => state + 1,
      _ChangeEvent.decrement => state - 1,
    };
  }
}
