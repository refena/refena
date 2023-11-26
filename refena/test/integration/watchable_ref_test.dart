import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../util/skip_microtasks.dart';

void main() {
  test('Should rebuild after next microtask', () async {
    final ref = RefenaContainer();

    final stateProvider = StateProvider((ref) => 10);
    final viewProvider = ViewProvider((ref) => ref.watch(stateProvider) * 2);

    expect(ref.read(viewProvider), 20);

    ref.notifier(stateProvider).setState((value) => value + 1);
    expect(ref.read(viewProvider), 20);

    await skipAllMicrotasks();
    expect(ref.read(viewProvider), 22);
  });

  test('Ref.watch should still return state after dispose', () {
    final ref = RefenaContainer();

    final stateProvider = StateProvider((ref) => 10);
    WatchableRef? watchableRef;
    final viewProvider = ViewProvider((ref) {
      watchableRef ??= ref;
      return ref.watch(stateProvider) * 2;
    });

    expect(ref.read(viewProvider), 20);

    ref.notifier(stateProvider).setState((value) => value + 1);
    expect(ref.read(viewProvider), 20);

    ref.dispose(viewProvider);

    expect(ref.getActiveProviders(), [stateProvider]);
    expect(watchableRef!.watch(stateProvider), 11);
    expect(ref.getActiveProviders(), [stateProvider]);
  });
}
