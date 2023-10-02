import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector_client/refena_inspector_client.dart';

class ActionEntry {
  final String actionId;
  final String name;
  final Map<String, ParamSpec> params;

  const ActionEntry({
    required this.actionId,
    required this.name,
    required this.params,
  });
}

class ActionState {
  /// A nested map of [ActionEntry]s.
  final Map<String, dynamic> actions;

  ActionState({required this.actions});

  ActionState copyWith({Map<String, dynamic>? actions}) {
    return ActionState(
      actions: actions ?? this.actions,
    );
  }
}

final actionProvider = ReduxProvider<ActionService, ActionState>((ref) {
  return ActionService();
});

class ActionService extends ReduxNotifier<ActionState> {
  @override
  ActionState init() => ActionState(actions: {});
}

class SetActionsAction extends ReduxAction<ActionService, ActionState> {
  final Map<String, dynamic> actions;

  SetActionsAction({
    required this.actions,
  });

  @override
  ActionState reduce() {
    final parsedActions = parseActionMap(
      raw: actions,
      actionPath: '',
    );
    return state.copyWith(actions: parsedActions);
  }
}

Map<String, dynamic> parseActionMap({
  required Map<String, dynamic> raw,
  required String actionPath,
}) {
  final parsedActions = <String, dynamic>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    final value = entry.value as Map<String, dynamic>;
    final path = actionPath.isEmpty ? key : '$actionPath.$key';

    if (value['\$type'] == 'action') {
      final rawParams = value['params'] as Map<String, dynamic>;
      parsedActions[key] = ActionEntry(
        actionId: path,
        name: key,
        params: {
          for (final entry in rawParams.entries)
            // ignore: invalid_use_of_internal_member
            entry.key: ParamSpec.internal(
              type: ParamType.values
                  .firstWhere((t) => t.name == entry.value['type']),
              required: entry.value['required'],
              defaultValue: entry.value['defaultValue'],
            ),
        },
      );
    } else {
      parsedActions[key] = parseActionMap(
        raw: value,
        actionPath: path,
      );
    }
  }
  return parsedActions;
}
