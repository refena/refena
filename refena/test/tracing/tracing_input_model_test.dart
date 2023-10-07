import 'package:refena/refena.dart';
import 'package:refena/src/id_reference.dart';
import 'package:refena/src/tools/tracing_input_model.dart';
import 'package:test/test.dart';

void main() {
  group('fromEvent', () {
    setUp(() {
      IdReference.reset();
    });

    test('Should build from nested actions', () {
      final notifier = _Notifier();
      final parentAction = _ParentAction();
      final childAction = _ChildAction();
      final events = [
        ActionDispatchedEvent(
          debugOrigin: 'A',
          debugOriginRef: LabeledReference.custom('A'),
          notifier: notifier,
          action: parentAction,
        ),
        ActionDispatchedEvent(
          debugOrigin: '_ParentAction',
          debugOriginRef: parentAction,
          notifier: notifier,
          action: childAction,
        ),
      ];
      expect(parentAction.id, 0);
      expect(childAction.id, 1);
      expect(events[0].id, 2);
      expect(events[1].id, 3);

      final inputEvents = events
          .map((e) => InputEvent.fromEvent(
                event: e,
                errorParser: null,
                shouldParseError: false,
              ))
          .toList();

      expect(inputEvents.length, 2);

      expect(inputEvents[0].id, 2);
      expect(inputEvents[0].parentAction, null);
      expect(inputEvents[0].actionId, 0);

      expect(inputEvents[1].id, 3);
      expect(inputEvents[1].parentAction, 0);
      expect(inputEvents[1].actionId, 1);
    });
  });
}

class _Notifier extends ReduxNotifier<int> {
  @override
  int init() => 0;
}

class _ParentAction extends AsyncReduxAction<_Notifier, int> {
  @override
  Future<int> reduce() async {
    await Future.delayed(const Duration(milliseconds: 100));
    dispatch(_ChildAction());
    return state + 1;
  }
}

class _ChildAction extends ReduxAction<_Notifier, int> {
  @override
  int reduce() {
    return state + 1;
  }
}
