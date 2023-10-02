import 'dart:async';
import 'dart:convert';

import 'package:refena/refena.dart';
import 'package:refena_inspector_client/src/inspector_action.dart';
import 'package:refena_inspector_client/src/protocol.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// This observer connects to the inspector server
/// and communicates the state of the app.
class RefenaInspectorObserver extends RefenaObserver {
  /// The host of the inspector server.
  final String? host;

  /// The port of the inspector server.
  final int port;

  /// The action map that will be displayed in the inspector.
  /// It can be nested.
  final Map<String, dynamic> actions;

  RefenaInspectorObserver({
    this.host,
    this.port = 9253,
    Map<String, dynamic> actions = const {},
  }) : actions = buildActionMap(actions);

  @override
  void init() async {
    while (true) {
      try {
        await runWebSocket();
        break;
      } catch (e) {
        print('Failed to connect to refena inspector server.');
        await Future.delayed(Duration(seconds: 3));
      }
    }
  }

  @override
  void handleEvent(RefenaEvent event) {}

  Future<void> runWebSocket() async {
    final wsUrl = Uri(scheme: 'ws', host: host ?? 'localhost', port: port);
    var channel = WebSocketChannel.connect(wsUrl);

    // https://github.com/dart-lang/web_socket_channel/issues/249
    await channel.ready;

    print('Connected to refena inspector server.');

    try {
      channel.sink.add(jsonEncode({
        'type': InspectorClientMessageType.hello.name,
        'payload': {
          'actions': getActionMapJson(actions),
        },
      }));
    } catch (e) {
      print('Failed to send hello message to refena inspector server: $e');
      rethrow;
    }

    await for (final message in channel.stream) {
      try {
        final json = jsonDecode(message);
        final type = InspectorServerMessageType.values
            .firstWhere((t) => t.name == json['type']);
        final payload = json['payload'];
        switch (type) {
          case InspectorServerMessageType.action:
            final actionId = payload['actionId'] as String;
            final params = payload['params'] as Map<String, dynamic>;
            final action = getAction(actionId);
            try {
              ref.dispatch(
                InspectorGlobalAction(
                  name: actionId,
                  params: params,
                  action: action.action,
                ),
              );
            } catch (_) {}
            break;
        }
      } catch (e) {
        print('Failed to parse refena inspector message: $message');
      }
    }
  }

  /// Returns the action map as JSON.
  Map<String, dynamic> getActionMapJson(Map<String, dynamic> actions) {
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
        Map<String, dynamic>() => getActionMapJson(value),
        _ => throw Exception('Invalid action: $key'),
      };
    }

    return result;
  }

  /// Returns the action with the given [actionId].
  /// The [actionId] is a dot-separated path to the action.
  InspectorAction getAction(String actionId) {
    final parts = actionId.split('.');
    dynamic action = actions;
    for (final part in parts) {
      action = action[part];
      if (action == null) {
        throw Exception('Action not found: $actionId');
      }
    }

    if (action is! InspectorAction) {
      throw Exception('Invalid action: $actionId');
    }

    return action;
  }

  /// Normalizes the action map to a nested map of [InspectorAction]s.
  static Map<String, dynamic> buildActionMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      result[key] = switch (value) {
        InspectorAction() => value,
        Map<String, dynamic>() => buildActionMap(value),
        void Function(Ref) f => InspectorAction(
            params: {},
            action: (ref, _) => f(ref),
          ),
        _ => throw Exception('Invalid action: $key'),
      };
    }

    return result;
  }
}

/// A global action that is dispatched by the [RefenaInspectorObserver]
/// when an action is sent from the inspector.
class InspectorGlobalAction extends GlobalAction {
  final String name;
  final Map<String, dynamic> params;
  final void Function(Ref ref, Map<String, dynamic> params) action;

  InspectorGlobalAction({
    required this.name,
    required this.params,
    required this.action,
  });

  @override
  void reduce() => action(ref, params);

  @override
  String get debugLabel => 'InspectorAction:$name';

  @override
  String toString() => 'InspectorAction(name: $name, params: $params)';
}
