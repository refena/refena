import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  group(RiverpieHistoryObserver, () {
    test('Should observe from the beginning', () {
      final observer = RiverpieHistoryObserver.all();
      final ref = RiverpieContainer(
        observer: observer,
      );

      final provider = StateProvider((ref) => 123);
      ref.read(provider);
      ref.notifier(provider).setState((old) => old + 1);

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

    test('Should observe after start', () {
      final observer = RiverpieHistoryObserver(HistoryObserverConfig(
        startImmediately: false,
      ));
      final ref = RiverpieContainer(
        observer: observer,
      );

      final provider = StateProvider((ref) => 123);
      ref.read(provider);
      ref.notifier(provider).setState((old) => old + 1);

      observer.start();
      ref.notifier(provider).setState((old) => old + 1);

      // Check events
      final notifier = ref.notifier(provider);
      expect(observer.history, [
        ChangeEvent(
          notifier: notifier,
          prev: 124,
          next: 125,
          rebuild: [],
        ),
      ]);
    });
  });
}
