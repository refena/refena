import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  test('Should change state', () {
    final counter = ReduxNotifier.test(
      redux: _Counter(),
    );

    expect(counter.state, 50);

    counter.dispatch(IncrementAction());
    expect(counter.state, 51);

    counter.setState(5);
    expect(counter.state, 5);

    counter.dispatch(DecrementAction());
    expect(counter.state, 4);
  });

  test('Should set initial state', () {
    final counter = ReduxNotifier.test(
      redux: _Counter(),
      initialState: 11,
    );

    expect(counter.state, 11);

    counter.dispatch(IncrementAction());
    expect(counter.state, 12);
  });
}

class _Counter extends ReduxNotifier<int> {
  @override
  int init() => 50;
}

class IncrementAction extends ReduxAction<_Counter, int> {
  @override
  int reduce() {
    return state + 1;
  }
}

class DecrementAction extends ReduxAction<_Counter, int> {
  @override
  int reduce() {
    return state - 1;
  }
}
