import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Should change state', () async {
    final tester = AsyncNotifier.test<_Counter, int>(
      notifier: _Counter(),
    );

    await skipAllMicrotasks();

    expect(tester.state, AsyncValue.data(50));

    tester.setState(AsyncValue.data(51));
    expect(tester.state, AsyncValue.data(51));

    tester.notifier.increment();
    await skipAllMicrotasks();
    expect(tester.state, AsyncValue.data(52));
  });

  test('Should set initial state', () async {
    final tester = AsyncNotifier.test<_Counter, int>(
      notifier: _Counter(),
      initialState: AsyncValue.data(11),
    );

    await skipAllMicrotasks();
    expect(tester.state, AsyncValue.data(11));

    tester.notifier.increment();
    await skipAllMicrotasks();
    expect(tester.state, AsyncValue.data(12));
  });

  test('Should access state', () async {
    final tester = AsyncNotifier.test<_Counter, int>(
      notifier: _Counter(),
    );

    await skipAllMicrotasks();
    expect(tester.state, AsyncValue.data(50));
    expect(tester.notifier.accessState(), 20);
  });
}

final _stateProvider = StateProvider((ref) => 20);

class _Counter extends AsyncNotifier<int> {
  @override
  Future<int> init() async => 50;

  void increment() {
    setState((snapshot) async => snapshot.curr! + 1);
  }

  int accessState() {
    return ref.read(_stateProvider);
  }
}
