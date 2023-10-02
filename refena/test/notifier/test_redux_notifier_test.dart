import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  test('Should change state', () {
    final counter = ReduxNotifier.test(
      redux: _Counter(),
    );

    expect(counter.state, 50);

    counter.dispatch(_IncrementAction());
    expect(counter.state, 51);

    counter.setState(5);
    expect(counter.state, 5);

    counter.dispatch(_DecrementAction());
    expect(counter.state, 4);
  });

  test('Should set initial state', () {
    final counter = ReduxNotifier.test(
      redux: _Counter(),
      initialState: 11,
    );

    expect(counter.state, 11);

    counter.dispatch(_IncrementAction());
    expect(counter.state, 12);
  });

  test('Should run initial action', () {
    final counter = ReduxNotifier.test(
      redux: _CounterWithInitialAction(),
      runInitialAction: true,
    );

    expect(counter.state, 20);
  });

  test('Should not run initial action', () {
    final counter = ReduxNotifier.test(
      redux: _CounterWithInitialAction(),
      runInitialAction: false,
    );

    expect(counter.state, 10);
  });

  test('Should run initial action with initial state', () {
    final counter = ReduxNotifier.test(
      redux: _CounterWithInitialAction(),
      runInitialAction: true,
      initialState: 5,
    );

    expect(counter.state, 15);
  });
}

class _Counter extends ReduxNotifier<int> {
  @override
  int init() => 50;
}

class _IncrementAction extends ReduxAction<_Counter, int> {
  @override
  int reduce() {
    return state + 1;
  }
}

class _DecrementAction extends ReduxAction<_Counter, int> {
  @override
  int reduce() {
    return state - 1;
  }
}

class _CounterWithInitialAction extends ReduxNotifier<int> {
  @override
  int init() => 10;

  @override
  get initialAction => _CounterInitialAction();
}

class _CounterInitialAction
    extends ReduxAction<_CounterWithInitialAction, int> {
  @override
  int reduce() {
    return state + 10;
  }
}
