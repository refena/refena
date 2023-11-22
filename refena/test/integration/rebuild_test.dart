import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../util/skip_microtasks.dart';

void main() {
  group(ViewProvider, () {
    test('Should rebuild with ref.rebuild', () async {
      final observer = RefenaHistoryObserver.only(
        rebuild: true,
        change: true,
      );
      final ref = RefenaContainer(
        observers: [observer],
      );

      final parentProvider = StateProvider((ref) => 0);
      int rebuildCount = 0;
      final viewProvider = ViewProvider((ref) {
        // We don't use watch to avoid automatic rebuilds
        rebuildCount++;
        return ref.read(parentProvider) + 1;
      });

      expect(ref.read(parentProvider), 0);
      expect(ref.read(viewProvider), 1);
      expect(rebuildCount, 1);

      ref.notifier(parentProvider).setState((old) => 10);
      expect(ref.read(parentProvider), 10);

      // Ensure that no rebuild happened
      await skipAllMicrotasks();
      expect(ref.read(viewProvider), 1);
      expect(rebuildCount, 1);

      // Trigger rebuild
      expect(observer.history.whereType<RebuildEvent>().toList(), isEmpty);
      final result = ref.rebuild(viewProvider);
      expect(observer.history.whereType<RebuildEvent>().toList().length, 1);
      expect(result, 11);
      expect(ref.read(viewProvider), 11);
      expect(rebuildCount, 2);

      // Check history
      final parentNotifier = ref.notifier(parentProvider);
      final viewNotifier = ref.anyNotifier(viewProvider);
      expect(observer.history, [
        ChangeEvent(
          notifier: parentNotifier,
          action: null,
          prev: 0,
          next: 10,
          rebuild: [],
        ),
        RebuildEvent(
          rebuildable: viewNotifier,
          causes: [],
          debugOrigin: ref,
          prev: 1,
          next: 11,
          rebuild: [],
        ),
      ]);
    });
  });

  group(ViewFamilyProvider, () {
    test('Should rebuild with ref.rebuild', () async {
      final observer = RefenaHistoryObserver.only(
        rebuild: true,
        change: true,
      );
      final ref = RefenaContainer(
        observers: [observer],
      );

      final parentProvider = StateProvider((ref) => 0);
      int rebuildCount = 0;
      final viewProvider = ViewProvider.family<int, int>((ref, param) {
        // We don't use watch to avoid automatic rebuilds
        rebuildCount++;
        return ref.read(parentProvider) + 1 + param;
      });

      expect(ref.read(parentProvider), 0);
      expect(ref.read(viewProvider(1)), 2);
      expect(rebuildCount, 1);

      ref.notifier(parentProvider).setState((old) => 10);
      expect(ref.read(parentProvider), 10);

      // Ensure that no rebuild happened
      await skipAllMicrotasks();
      expect(ref.read(viewProvider(1)), 2);
      expect(rebuildCount, 1);

      // Trigger rebuild
      expect(observer.history.whereType<RebuildEvent>().toList(), isEmpty);
      final result = ref.rebuild(viewProvider(1));
      expect(observer.history.whereType<RebuildEvent>().toList().length, 1);
      expect(result, 12);
      expect(ref.read(viewProvider(1)), 2);
      expect(rebuildCount, 2);

      // Family provider notices this change in the next micro task
      await skipAllMicrotasks();
      expect(observer.history.whereType<RebuildEvent>().toList().length, 2);
      expect(ref.read(viewProvider(1)), 12);
      expect(rebuildCount, 2);

      // initialize more parameters
      expect(ref.read(viewProvider(2)), 13);
      expect(ref.read(viewProvider(3)), 14);
      expect(rebuildCount, 4);

      // Trigger rebuild (all children)
      expect(observer.history.whereType<RebuildEvent>().toList().length, 2);
      ref.notifier(parentProvider).setState((old) => 20);
      ref.rebuild(viewProvider);
      expect(rebuildCount, 7);
      expect(observer.history.whereType<RebuildEvent>().toList().length, 5);

      // Family provider notices this change in the next micro task
      await skipAllMicrotasks();
      expect(observer.history.whereType<RebuildEvent>().toList().length, 6);
    });
  });

  group(FutureProvider, () {
    test('Should rebuild with ref.rebuild', () async {
      final observer = RefenaHistoryObserver.only(
        rebuild: true,
        change: true,
      );
      final ref = RefenaContainer(
        observers: [observer],
      );

      final parentProvider = StateProvider((ref) => 0);
      int rebuildCount = 0;
      final futureProvider = FutureProvider((ref) async {
        // We don't use watch to avoid automatic rebuilds
        rebuildCount++;
        await Future.delayed(Duration(milliseconds: 10));
        return ref.read(parentProvider) + 1;
      });

      expect(ref.read(parentProvider), 0);
      expect(ref.read(futureProvider), AsyncValue<int>.loading());

      final firstResult = await ref.future(futureProvider);
      expect(firstResult, 1);
      expect(ref.read(futureProvider), AsyncValue<int>.data(1));
      expect(rebuildCount, 1);

      ref.notifier(parentProvider).setState((old) => 10);
      expect(ref.read(parentProvider), 10);

      // Ensure that no rebuild happened
      await skipAllMicrotasks();
      expect(ref.read(futureProvider), AsyncValue<int>.data(1));
      expect(rebuildCount, 1);

      // Trigger rebuild
      expect(observer.history.whereType<RebuildEvent>().toList(), isEmpty);
      final result = ref.rebuild(futureProvider);
      expect(observer.history.whereType<RebuildEvent>().toList().length, 1);
      expect(ref.read(futureProvider), AsyncValue<int>.loading(1));

      // Wait for the future to complete
      expect(await result, 11);
      expect(ref.read(futureProvider), AsyncValue<int>.data(11));
      expect(rebuildCount, 2);

      // Check history
      final parentNotifier = ref.notifier(parentProvider);
      final futureNotifier = ref.anyNotifier(futureProvider);
      expect(observer.history, [
        ChangeEvent(
          notifier: futureNotifier,
          action: null,
          prev: AsyncValue<int>.loading(),
          next: AsyncValue<int>.data(1),
          rebuild: [],
        ),
        ChangeEvent(
          notifier: parentNotifier,
          action: null,
          prev: 0,
          next: 10,
          rebuild: [],
        ),
        RebuildEvent(
          rebuildable: futureNotifier,
          causes: [],
          debugOrigin: ref,
          prev: AsyncValue<int>.data(1),
          next: AsyncValue<int>.loading(1),
          rebuild: [],
        ),
        ChangeEvent(
          notifier: futureNotifier,
          action: null,
          prev: AsyncValue<int>.loading(1),
          next: AsyncValue<int>.data(11),
          rebuild: [],
        ),
      ]);
    });
  });

  group(FutureFamilyProvider, () {
    test('Should rebuild with ref.rebuild', () async {
      final observer = RefenaHistoryObserver.only(
        rebuild: true,
        change: true,
      );
      final ref = RefenaContainer(
        observers: [observer],
      );

      final parentProvider = StateProvider((ref) => 0);
      int rebuildCount = 0;
      final futureProvider = FutureFamilyProvider<int, int>((ref, param) async {
        // We don't use watch to avoid automatic rebuilds
        rebuildCount++;
        await Future.delayed(Duration(milliseconds: 10));
        return ref.read(parentProvider) + 1 + param;
      });

      expect(ref.read(parentProvider), 0);
      expect(ref.read(futureProvider(1)), AsyncValue<int>.loading());

      final firstResult = await ref.future(futureProvider(1));
      expect(firstResult, 2);
      expect(rebuildCount, 1);
      expect(ref.read(futureProvider(1)), AsyncValue<int>.loading());

      // Family provider notices this change in the next micro task
      await skipAllMicrotasks();
      expect(ref.read(futureProvider(1)), AsyncValue<int>.data(2));

      ref.notifier(parentProvider).setState((old) => 10);
      expect(ref.read(parentProvider), 10);

      // Ensure that no rebuild happened
      await skipAllMicrotasks();
      expect(ref.read(futureProvider(1)), AsyncValue<int>.data(2));
      expect(rebuildCount, 1);

      // Trigger rebuild
      expect(observer.history.whereType<RebuildEvent>().toList().length, 1);
      final result = ref.rebuild(futureProvider(1));
      expect(observer.history.whereType<RebuildEvent>().toList().length, 2);
      expect(ref.read(futureProvider(1)), AsyncValue<int>.data(2));

      // Family provider notices this change in the next micro task
      await skipAllMicrotasks();
      expect(ref.read(futureProvider(1)), AsyncValue<int>.loading(2));

      expect(await result, 12);
      expect(ref.read(futureProvider(1)), AsyncValue<int>.loading(2));

      // Family provider notices this change in the next micro task
      await skipAllMicrotasks();
      expect(ref.read(futureProvider(1)), AsyncValue<int>.data(12));
      expect(observer.history.whereType<RebuildEvent>().toList().length, 4);
      expect(rebuildCount, 2);

      // initialize more parameters
      expect(ref.read(futureProvider(2)), AsyncValue<int>.loading());
      expect(ref.read(futureProvider(3)), AsyncValue<int>.loading());
      expect(rebuildCount, 4);

      // wait until all futures are completed
      await Future.delayed(Duration(milliseconds: 20));
      expect(ref.read(futureProvider(1)), AsyncValue<int>.data(12));
      expect(ref.read(futureProvider(2)), AsyncValue<int>.data(13));
      expect(ref.read(futureProvider(3)), AsyncValue<int>.data(14));
      expect(rebuildCount, 4);

      // Trigger rebuild (all children)
      expect(observer.history.whereType<RebuildEvent>().toList().length, 6);
      ref.notifier(parentProvider).setState((old) => 20);
      ref.rebuild(futureProvider);
      expect(observer.history.whereType<RebuildEvent>().toList().length, 9);
      expect(rebuildCount, 7);

      // Family provider notices this change in the next micro task
      await skipAllMicrotasks();
      expect(observer.history.whereType<RebuildEvent>().toList().length, 10);
    });
  });

  group(StreamProvider, () {
    test('Should rebuild with ref.rebuild', () async {
      final observer = RefenaHistoryObserver.only(
        rebuild: true,
        change: true,
      );
      final ref = RefenaContainer(
        observers: [observer],
      );

      final parentProvider = StateProvider((ref) => 0);
      int rebuildCount = 0;
      final streamProvider = StreamProvider((ref) {
        stream() async* {
          // We don't use watch to avoid automatic rebuilds
          rebuildCount++;
          await Future.delayed(Duration(milliseconds: 10));
          yield ref.read(parentProvider) + 1;
        }

        return stream().asBroadcastStream();
      });

      expect(ref.read(parentProvider), 0);
      expect(ref.read(streamProvider), AsyncValue<int>.loading());

      final firstResult = await ref.future(streamProvider);
      expect(firstResult, 1);
      expect(ref.read(streamProvider), AsyncValue<int>.data(1));
      expect(rebuildCount, 1);

      ref.notifier(parentProvider).setState((old) => 10);
      expect(ref.read(parentProvider), 10);

      // Ensure that no rebuild happened
      await skipAllMicrotasks();
      expect(ref.read(streamProvider), AsyncValue<int>.data(1));
      expect(rebuildCount, 1);

      // Trigger rebuild
      expect(observer.history.whereType<RebuildEvent>().toList(), isEmpty);
      final result = ref.rebuild(streamProvider);
      expect(observer.history.whereType<RebuildEvent>().toList().length, 1);
      expect(ref.read(streamProvider), AsyncValue<int>.loading(1));

      // Wait for the future to complete
      expect(await result.first, 11);
      expect(ref.read(streamProvider), AsyncValue<int>.data(11));
      expect(rebuildCount, 2);

      // Check history
      final parentNotifier = ref.notifier(parentProvider);
      final streamNotifier = ref.anyNotifier(streamProvider);
      expect(observer.history, [
        ChangeEvent(
          notifier: streamNotifier,
          action: null,
          prev: AsyncValue<int>.loading(),
          next: AsyncValue<int>.data(1),
          rebuild: [],
        ),
        ChangeEvent(
          notifier: parentNotifier,
          action: null,
          prev: 0,
          next: 10,
          rebuild: [],
        ),
        RebuildEvent(
          rebuildable: streamNotifier,
          causes: [],
          debugOrigin: ref,
          prev: AsyncValue<int>.data(1),
          next: AsyncValue<int>.loading(1),
          rebuild: [],
        ),
        ChangeEvent(
          notifier: streamNotifier,
          action: null,
          prev: AsyncValue<int>.loading(1),
          next: AsyncValue<int>.data(11),
          rebuild: [],
        ),
      ]);
    });
  });

  group(StreamFamilyProvider, () {
    test('Should rebuild with ref.rebuild', () async {
      final observer = RefenaHistoryObserver.only(
        rebuild: true,
        change: true,
      );
      final ref = RefenaContainer(
        observers: [observer],
      );

      final parentProvider = StateProvider((ref) => 0);
      int rebuildCount = 0;
      final streamProvider = StreamFamilyProvider<int, int>((ref, param) {
        stream() async* {
          // We don't use watch to avoid automatic rebuilds
          rebuildCount++;
          await Future.delayed(Duration(milliseconds: 10 + param));
          yield ref.read(parentProvider) + 1 + param;
        }

        return stream().asBroadcastStream();
      });

      expect(ref.read(parentProvider), 0);
      expect(ref.read(streamProvider(1)), AsyncValue<int>.loading());

      final firstResult = await ref.future(streamProvider(1));
      expect(firstResult, 2);
      expect(rebuildCount, 1);
      expect(ref.read(streamProvider(1)), AsyncValue<int>.loading());

      // Family provider notices this change in the next micro task
      await skipAllMicrotasks();
      expect(ref.read(streamProvider(1)), AsyncValue<int>.data(2));

      ref.notifier(parentProvider).setState((old) => 10);
      expect(ref.read(parentProvider), 10);

      // Ensure that no rebuild happened
      await skipAllMicrotasks();
      expect(ref.read(streamProvider(1)), AsyncValue<int>.data(2));
      expect(rebuildCount, 1);

      // Trigger rebuild
      expect(observer.history.whereType<RebuildEvent>().toList().length, 1);
      final result = ref.rebuild(streamProvider(1));
      expect(observer.history.whereType<RebuildEvent>().toList().length, 2);
      expect(ref.read(streamProvider(1)), AsyncValue<int>.data(2));

      // Family provider notices this change in the next micro task
      await skipAllMicrotasks();
      expect(ref.read(streamProvider(1)), AsyncValue<int>.loading(2));

      expect(await result.first, 12);
      expect(ref.read(streamProvider(1)), AsyncValue<int>.loading(2));

      // Family provider notices this change in the next micro task
      await skipAllMicrotasks();
      expect(ref.read(streamProvider(1)), AsyncValue<int>.data(12));
      expect(rebuildCount, 2);

      // initialize more parameters
      expect(ref.read(streamProvider(2)), AsyncValue<int>.loading());
      expect(ref.read(streamProvider(3)), AsyncValue<int>.loading());

      // wait until all futures are completed
      await Future.delayed(Duration(milliseconds: 20));
      expect(ref.read(streamProvider(1)), AsyncValue<int>.data(12));
      expect(ref.read(streamProvider(2)), AsyncValue<int>.data(13));
      expect(ref.read(streamProvider(3)), AsyncValue<int>.data(14));
      expect(rebuildCount, 4);

      // Trigger rebuild (all children)
      expect(observer.history.whereType<RebuildEvent>().toList().length, 6);
      ref.notifier(parentProvider).setState((old) => 20);
      ref.rebuild(streamProvider);
      expect(observer.history.whereType<RebuildEvent>().toList().length, 9);

      // Family provider notices this change in the next micro task
      await skipAllMicrotasks();
      expect(rebuildCount, 7);
      expect(observer.history.whereType<RebuildEvent>().toList().length, 10);

      // wait until all futures are completed
      await Future.delayed(Duration(milliseconds: 20));
      expect(ref.read(streamProvider(1)), AsyncValue<int>.data(22));
      expect(ref.read(streamProvider(2)), AsyncValue<int>.data(23));
      expect(ref.read(streamProvider(3)), AsyncValue<int>.data(24));
      expect(rebuildCount, 7);

      // 3 rebuilds for 3 change events
      expect(observer.history.whereType<RebuildEvent>().toList().length, 13);
    });
  });
}
