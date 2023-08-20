import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  test('Should change state', () {
    final counter = ReduxNotifier.test(
      redux: _Counter(),
    );

    expect(counter.state, 50);

    counter.emit(_ChangeEvent.increment);
    expect(counter.state, 51);

    counter.setState(5);
    expect(counter.state, 5);

    counter.emit(_ChangeEvent.decrement);
    expect(counter.state, 4);
  });

  test('Should set initial state', () {
    final counter = ReduxNotifier.test(
      redux: _Counter(),
      initialState: 11,
    );

    expect(counter.state, 11);

    counter.emit(_ChangeEvent.increment);
    expect(counter.state, 12);
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
