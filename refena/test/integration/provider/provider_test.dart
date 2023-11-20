import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  test('Should read the value', () {
    final provider = Provider((ref) => 123);
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), 123);

    // Check events
    final notifier = ref.anyNotifier<ImmutableNotifier<int>, int>(provider);
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: 123,
      ),
    ]);
  });

  test('Should read the nested value', () {
    final providerA = Provider((ref) => 'AAA');
    final providerB = Provider((ref) => 'BBB');
    final providerC = Provider((ref) {
      final a = ref.read(providerA);
      final b = ref.read(providerB);
      return '$a $b CCC';
    });
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(providerC), 'AAA BBB CCC');

    // Check events
    final notifierA = ref.anyNotifier<ImmutableNotifier<String>, String>(
      providerA,
    );
    final notifierB = ref.anyNotifier<ImmutableNotifier<String>, String>(
      providerB,
    );
    final notifierC = ref.anyNotifier<ImmutableNotifier<String>, String>(
      providerC,
    );

    expect(observer.history, [
      ProviderInitEvent(
        provider: providerA,
        notifier: notifierA,
        cause: ProviderInitCause.access,
        value: 'AAA',
      ),
      ProviderInitEvent(
        provider: providerB,
        notifier: notifierB,
        cause: ProviderInitCause.access,
        value: 'BBB',
      ),
      ProviderInitEvent(
        provider: providerC,
        notifier: notifierC,
        cause: ProviderInitCause.access,
        value: 'AAA BBB CCC',
      ),
    ]);
  });
}
