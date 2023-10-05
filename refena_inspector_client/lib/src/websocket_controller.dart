import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:refena/refena.dart';
import 'package:refena_inspector_client/src/builder/actions_builder.dart';
import 'package:refena_inspector_client/src/builder/graph_builder.dart';
import 'package:refena_inspector_client/src/builder/tracing_builder.dart';
import 'package:refena_inspector_client/src/inspector_action.dart';
import 'package:refena_inspector_client/src/observer.dart';
import 'package:refena_inspector_client/src/protocol.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

@internal
class WebSocketController {
  final Ref ref;
  final WebSocketSink sink;
  final Stream stream;
  final Map<String, dynamic> actions;
  final String theme;
  final ErrorParser? errorParser;

  /// Last graph sent to the server serialized as JSON.
  /// If the graph is the same, then it will not be sent again.
  String? _lastGraph;

  WebSocketController({
    required this.ref,
    required this.sink,
    required this.stream,
    required this.actions,
    required this.theme,
    required this.errorParser,
  });

  Future<void> handleMessages() async {
    try {
      _sendHello();
      ref.message('Connected to Refena Inspector.');
    } catch (e) {
      print('Failed to send hello message to refena inspector server: $e');
      rethrow;
    }
    await for (final message in stream) {
      try {
        final json = jsonDecode(message);
        final type = InspectorServerMessageType.values
            .firstWhere((t) => t.name == json['type']);
        final payload = json['payload'];
        switch (type) {
          case InspectorServerMessageType.action:
            _handleActionMessage(payload);
            break;
        }
      } catch (e) {
        print('Failed to parse refena inspector message: $message');
      }
    }
  }

  void sendEvents(List<RefenaEvent> events) {
    final message = jsonEncode({
      'type': InspectorClientMessageType.event.name,
      'payload': {
        'events': TracingBuilder.buildEventsDto(
          events: events,
          errorParser: errorParser,
        ),
      },
    });
    sink.add(message);
  }

  void sendGraph() {
    final message = jsonEncode({
      'type': InspectorClientMessageType.graph.name,
      'payload': {
        'graph': GraphBuilder.buildDto(ref),
      },
    });
    if (message == _lastGraph) {
      return;
    }
    _lastGraph = message;
    sink.add(message);
  }

  void _sendHello() {
    sink.add(jsonEncode({
      'type': InspectorClientMessageType.hello.name,
      'payload': {
        if (ref.notifier(tracingProvider).initialized)
          'events': TracingBuilder.buildFullDto(
            ref: ref,
            errorParser: errorParser,
          ),
        'graph': GraphBuilder.buildDto(ref),
        'actions': ActionsBuilder.convertToJson(actions),
        'theme': theme,
      },
    }));
  }

  void _handleActionMessage(Map<String, dynamic> payload) {
    final actionId = payload['actionId'] as String;
    final params = payload['params'] as Map<String, dynamic>;
    final action = _getAction(actionId);
    try {
      ref.dispatch(
        InspectorGlobalAction(
          name: actionId,
          params: params,
          action: action.action,
        ),
      );
    } catch (_) {}
  }

  /// Returns the action with the given [actionId].
  /// The [actionId] is a dot-separated path to the action.
  InspectorAction _getAction(String actionId) {
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
}
