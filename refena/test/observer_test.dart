import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  group(RefenaHistoryObserver, () {
    test('Should observe from the beginning', () {
      final observer = RefenaHistoryObserver.all();
      final ref = RefenaContainer(
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
          action: null,
          prev: 123,
          next: 124,
          rebuild: [],
        ),
      ]);
    });

    test('Should observe after start', () {
      final observer = RefenaHistoryObserver(HistoryObserverConfig(
        startImmediately: false,
      ));
      final ref = RefenaContainer(
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
          action: null,
          prev: 124,
          next: 125,
          rebuild: [],
        ),
      ]);
    });
  });
}
