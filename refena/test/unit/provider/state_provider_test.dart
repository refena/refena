import 'package:refena/refena.dart';
import 'package:test/test.dart';

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
}
