import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Should trigger rebuild', () async {
    final notifier = _Counter(123);
    final provider = ChangeNotifierProvider((ref) => notifier);
    final viewProvider = ViewProvider<int>((ref) {
      return ref.watch(provider).value;
    });
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.notifier(provider).value, 123);
    expect(ref.read(viewProvider), 123);

    ref.notifier(provider).increment();
    await skipAllMicrotasks();

    expect(ref.notifier(provider).value, 124);
    expect(ref.read(viewProvider), 124);

    // Check events
    final viewNotifier = ref.anyNotifier(viewProvider);
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: null,
      ),
      ProviderInitEvent(
        provider: viewProvider,
        notifier: viewNotifier,
        cause: ProviderInitCause.access,
        value: 123,
      ),
      ChangeEvent(
        notifier: notifier,
        action: null,
        prev: null,
        next: null,
        rebuild: [viewNotifier],
      ),
      RebuildEvent(
        rebuildable: viewNotifier,
        causes: [
          ChangeEvent<void>(
            notifier: notifier,
            action: null,
            prev: null,
            next: null,
            rebuild: [viewNotifier],
          ),
        ],
        prev: 123,
        next: 124,
        rebuild: [],
      ),
    ]);
  });

  test('Should trigger onChanged', () async {
    final provider = ChangeNotifierProvider(
      (ref) => _Counter(123),
      onChanged: (ref) => ref.message('Changed!'),
    );
    final observer = RefenaHistoryObserver.only(
      message: true,
    );
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.notifier(provider).value, 123);
    expect(observer.messages, isEmpty);

    ref.notifier(provider).increment();
    await skipAllMicrotasks();

    expect(ref.notifier(provider).value, 124);
    expect(observer.messages, [
      'Changed!',
    ]);
  });
}

class _Counter extends ChangeNotifier {
  int value;

  _Counter(this.value);

  void increment() {
    value++;
    notifyListeners();
  }
}
