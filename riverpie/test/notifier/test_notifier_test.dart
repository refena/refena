import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  test('Should change state', () {
    final tester = Notifier.test<_Counter, int>(
      notifier: _Counter(),
    );

    expect(tester.state, 50);

    tester.setState(51);
    expect(tester.state, 51);

    tester.notifier.increment();
    expect(tester.state, 52);
  });

  test('Should set initial state', () {
    final tester = Notifier.test<_Counter, int>(
      notifier: _Counter(),
      initialState: 11,
    );

    expect(tester.state, 11);

    tester.notifier.increment();
    expect(tester.state, 12);
  });
}

class _Counter extends Notifier<int> {
  @override
  int init() => 50;

  void increment() {
    state++;
  }
}
