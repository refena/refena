import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  late RefenaHistoryObserver observer;

  setUp(() {
    observer = RefenaHistoryObserver.only(
      change: true,
      actionDispatched: true,
      actionError: true,
    );
  });

  test('Should dispatch external action', () {
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(_baseProvider), 0);
    expect(ref.read(_externalProvider), 'A');

    final result = ref.redux(_baseProvider).dispatch(_AddAction());
    expect(result, 1);
    expect(ref.read(_baseProvider), 1);
    expect(ref.read(_externalProvider), 'AB');

    // Check events
    final baseNotifier = ref.notifier(_baseProvider);
    final externalNotifier = ref.notifier(_externalProvider);
    expect(observer.history, [
      ActionDispatchedEvent(
        debugOrigin: 'RefenaContainer',
        debugOriginRef: ref,
        notifier: baseNotifier,
        action: _AddAction(),
      ),
      ActionDispatchedEvent(
        debugOrigin: '_AddAction',
        debugOriginRef: _AddAction(),
        notifier: externalNotifier,
        action: _ExternalAction(),
      ),
      ChangeEvent(
        notifier: externalNotifier,
        action: _ExternalAction(),
        prev: 'A',
        next: 'AB',
        rebuild: [],
      ),
      ChangeEvent(
        notifier: baseNotifier,
        action: _AddAction(),
        prev: 0,
        next: 1,
        rebuild: [],
      ),
    ]);
  });
}

final _baseProvider = ReduxProvider<_BaseService, int>((ref) {
  return _BaseService(ref.notifier(_externalProvider));
});

final _externalProvider = ReduxProvider<_ExternalService, String>((ref) {
  return _ExternalService();
});

class _BaseService extends ReduxNotifier<int> {
  final _ExternalService externalService;

  _BaseService(this.externalService);

  @override
  int init() => 0;
}

class _AddAction extends ReduxAction<_BaseService, int> {
  @override
  int reduce() {
    external(notifier.externalService).dispatch(_ExternalAction());
    return state + 1;
  }

  @override
  bool operator ==(Object other) {
    return other is _AddAction;
  }

  @override
  int get hashCode => 0;
}

class _ExternalService extends ReduxNotifier<String> {
  @override
  String init() => 'A';
}

class _ExternalAction extends ReduxAction<_ExternalService, String> {
  @override
  String reduce() => '${state}B';

  @override
  bool operator ==(Object other) {
    return other is _ExternalAction;
  }

  @override
  int get hashCode => 0;
}
