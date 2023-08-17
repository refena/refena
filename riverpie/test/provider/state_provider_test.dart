import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  test('Single provider test', () {
    final provider = StateProvider((ref) => 123);
    final observer = RiverpieHistoryObserver.all();
    final ref = RiverpieContainer(
      observer: observer,
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
        prev: 123,
        next: 124,
        rebuild: [],
      ),
    ]);
  });
}
