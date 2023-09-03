import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  test('Should call postInit', () {
    final observer = RiverpieHistoryObserver.only(
      providerInit: true,
      change: true,
    );
    final ref = RiverpieContainer(
      observer: observer,
    );

    final provider = NotifierProvider<_Counter, int>((ref) => _Counter());

    expect(ref.read(provider), 300);

    // Check events
    final notifier = ref.notifier(provider);
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: 100,
      ),
      ChangeEvent(
        notifier: notifier,
        action: null,
        prev: 100,
        next: 300,
        rebuild: [],
      ),
    ]);
  });
}

class _Counter extends Notifier<int> {
  @override
  int init() => 100;

  @override
  void postInit() {
    state += 200;
  }
}
