import 'package:refena/refena.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  test('Should trigger onChanged', () async {
    final provider = ReduxProvider<_ReduxCounter, int>(
      (ref) => _ReduxCounter(),
      onChanged: (prev, next, ref) => ref.dispatch(_MessageAction(
        'Change from $prev to $next',
      )),
    );
    final observer = RefenaHistoryObserver.only(
      actionDispatched: true,
    );
    final ref = RefenaContainer(
      observers: [observer],
    );

    expect(ref.read(provider), 0);

    ref.redux(provider).dispatch(_AddAction());

    expect(ref.read(provider), 1);
    expect(observer.dispatchedActions, [
      _AddAction(),
    ]);
    await skipAllMicrotasks();

    expect(observer.dispatchedActions, [
      _AddAction(),
      _MessageAction('Change from 0 to 1'),
    ]);

    final messageActionEvent = observer.history.last as ActionDispatchedEvent;
    expect(
      messageActionEvent.debugOrigin,
      'ReduxProvider<_ReduxCounter, int>.onChanged',
    );
    expect(messageActionEvent.debugOriginRef, provider);
  });
}

class _ReduxCounter extends ReduxNotifier<int> {
  @override
  int init() => 0;
}

class _AddAction extends ReduxAction<_ReduxCounter, int> {
  @override
  int reduce() {
    return state + 1;
  }

  @override
  bool operator ==(Object other) {
    return other is _AddAction;
  }

  @override
  int get hashCode => 0;
}

class _MessageAction extends GlobalAction {
  final String message;

  _MessageAction(this.message);

  @override
  void reduce() {}

  @override
  bool operator ==(Object other) {
    return other is _MessageAction && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
