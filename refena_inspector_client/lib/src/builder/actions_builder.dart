import 'package:meta/meta.dart';
import 'package:refena/refena.dart';
import 'package:refena_inspector_client/src/inspector_action.dart';

@internal
class ActionsBuilder {
  /// Normalizes the action map to a nested map of [InspectorAction]s.
  static Map<String, dynamic> normalizeActionMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      result[key] = switch (value) {
        InspectorAction() => value,
        Map<String, dynamic>() => normalizeActionMap(value),
        void Function(Ref) f => InspectorAction(
            params: {},
            action: (ref, _) => f(ref),
          ),
        _ => throw Exception('Invalid action: $key'),
      };
    }

    return result;
  }

  /// Returns the action map as JSON.
  static Map<String, dynamic> convertToJson(Map<String, dynamic> actions) {
    final result = <String, dynamic>{};
    for (final entry in actions.entries) {
      final key = entry.key;
      final value = entry.value;

      result[key] = switch (value) {
        InspectorAction() => {
            '\$type': 'action', // a hint to deserialize
            'params': {
              for (final param in value.params.entries)
                param.key: {
                  'type': param.value.type.name,
                  'required': param.value.required,
                  'defaultValue': param.value.defaultValue,
                },
            },
          },
        Map<String, dynamic>() => convertToJson(value),
        _ => throw Exception('Invalid action: $key'),
      };
    }

    return result;
  }
}
