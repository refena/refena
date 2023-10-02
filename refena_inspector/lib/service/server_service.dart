import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector/service/action_service.dart';

// ignore: implementation_imports
import 'package:refena_inspector_client/src/protocol.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final _logger = Logger('InspectorServer');

class ServerState {
  final bool running;
  final bool clientConnected;
  final WebSocketSink? sink;

  ServerState({
    required this.running,
    required this.clientConnected,
    required this.sink,
  });

  ServerState copyWith({
    bool? running,
    bool? clientConnected,
    WebSocketSink? sink,
  }) {
    return ServerState(
      running: running ?? this.running,
      clientConnected: clientConnected ?? this.clientConnected,
      sink: sink ?? this.sink,
    );
  }

  @override
  String toString() {
    return 'ServerState(running: $running, clientConnected: $clientConnected)';
  }
}

final serverProvider = ReduxProvider<InspectorServer, ServerState>((ref) {
  return InspectorServer();
});

class InspectorServer extends ReduxNotifier<ServerState> {
  @override
  ServerState init() {
    return ServerState(
      running: false,
      clientConnected: false,
      sink: null,
    );
  }

  @override
  get initialAction => StartServerAction();
}

class StartServerAction extends AsyncReduxAction<InspectorServer, ServerState> {
  @override
  Future<ServerState> reduce() async {
    var handler = webSocketHandler((WebSocketChannel webSocket) async {
      dispatch(_SetSinkAction(sink: webSocket.sink));
      await for (final message in webSocket.stream) {
        _handleMessage(message);
      }
    });

    final server = await shelf_io.serve(handler, 'localhost', 9253);
    _logger.info('Serving at ws://${server.address.host}:${server.port}');
    return state.copyWith(
      running: true,
    );
  }
}

class _SetSinkAction extends ReduxAction<InspectorServer, ServerState> {
  final WebSocketSink sink;

  _SetSinkAction({
    required this.sink,
  });

  @override
  ServerState reduce() {
    return state.copyWith(
      sink: sink,
    );
  }
}

class _ClientConnectedAction extends ReduxAction<InspectorServer, ServerState> {
  @override
  ServerState reduce() {
    return state.copyWith(
      clientConnected: true,
    );
  }
}

/// Sends an action to the client.
class SendActionAction extends ReduxAction<InspectorServer, ServerState> {
  final String actionId;
  final Map<String, dynamic> params;

  SendActionAction({
    required this.actionId,
    required this.params,
  });

  @override
  ServerState reduce() {
    state.sink!.add(jsonEncode({
      'type': InspectorServerMessageType.action.name,
      'payload': {
        'actionId': actionId,
        'params': params,
      },
    }));
    return state;
  }
}

void _handleMessage(dynamic message) {
  final json = jsonDecode(message) as Map<String, dynamic>;
  final type = InspectorClientMessageType.values
      .firstWhere((t) => t.name == json['type']);
  final payload = json['payload'];

  final ref = RefenaScope.defaultRef;
  switch (type) {
    case InspectorClientMessageType.hello:
      final actions = payload['actions'] as Map<String, dynamic>;
      ref.redux(actionProvider).dispatch(SetActionsAction(actions: actions));
      ref.redux(serverProvider).dispatch(_ClientConnectedAction());
      break;
  }
}
