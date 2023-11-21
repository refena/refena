import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  group('Should compare with "==" correctly', () {
    test(RebuildEvent, () {
      final viewNotifier = ViewProviderNotifier<int>((ref) => 1);
      final stateNotifier = StateNotifier<int>(100);

      final eventA = RebuildEvent(
        rebuildable: viewNotifier,
        causes: [
          ChangeEvent(
            notifier: stateNotifier,
            action: null,
            prev: 0,
            next: 1,
            rebuild: [viewNotifier],
          ),
        ],
        debugOrigin: null,
        prev: 100,
        next: 101,
        rebuild: [viewNotifier],
      );

      final eventB = RebuildEvent(
        rebuildable: viewNotifier,
        causes: [
          ChangeEvent(
            notifier: stateNotifier,
            action: null,
            prev: 0,
            next: 1,
            rebuild: [viewNotifier],
          ),
        ],
        debugOrigin: null,
        prev: 100,
        next: 101,
        rebuild: [viewNotifier],
      );

      expect(eventA == eventB, true);
    });
  });
}
