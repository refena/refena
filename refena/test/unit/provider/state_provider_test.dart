import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Single provider test', () {
    final provider = StateProvider((ref) => 123);
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), 123);

    ref.notifier(provider).setState((old) => old + 1);

    expect(ref.read(provider), 124);

    // Check events
    final notifier = ref.notifier(provider);
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: 123,
      ),
      ChangeEvent(
        notifier: notifier,
        action: null,
        prev: 123,
        next: 124,
        rebuild: [],
      ),
    ]);
  });

  test('Should trigger onChanged', () async {
    final provider = StateProvider(
      (ref) => 123,
      onChanged: (prev, next, ref) => ref.message('Change from $prev to $next'),
    );
    final observer = RefenaHistoryObserver.only(
      message: true,
    );
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), 123);

    ref.notifier(provider).setState((old) => old + 1);
    await skipAllMicrotasks();

    expect(ref.read(provider), 124);
    expect(observer.messages, [
      'Change from 123 to 124',
    ]);

    ref.dispose(provider);

    ref.notifier(provider).setState((old) => old + 1);
    await skipAllMicrotasks();

    expect(ref.read(provider), 124);
    expect(observer.messages, [
      'Change from 123 to 124',
      'Change from 123 to 124',
    ]);
  });
}
