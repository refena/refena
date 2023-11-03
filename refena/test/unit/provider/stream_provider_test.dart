import 'dart:async';

import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Single provider test', () async {
    final controller = StreamController<int>();
    final provider = StreamProvider((ref) => controller.stream);
    final observer = RefenaHistoryObserver.all();
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), AsyncValue<int>.loading());

    controller.add(123);
    await skipAllMicrotasks();

    expect(ref.read(provider), AsyncValue<int>.data(123));

    // Check events
    final notifier = ref.anyNotifier(provider);
    expect(observer.history, [
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: AsyncValue<int>.loading(),
      ),
      ChangeEvent(
        notifier: notifier,
        action: null,
        prev: AsyncValue<int>.loading(),
        next: AsyncValue<int>.data(123),
        rebuild: [],
      ),
    ]);
  });
}
