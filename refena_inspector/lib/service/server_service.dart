import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector/pages/home_page_controller.dart';
import 'package:refena_inspector/service/action_service.dart';
import 'package:refena_inspector/service/graph_service.dart';
import 'package:refena_inspector/service/settings_service.dart';
import 'package:refena_inspector/service/tracing_service.dart';

// ignore: implementation_imports
import 'package:refena_inspector_client/src/protocol.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final _logger = Logger('InspectorServer');

/// The state of the server.
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
  return InspectorServer(
    ref.notifier(homePageControllerProvider),
    ref.notifier(eventTracingProvider),
  );
});

class InspectorServer extends ReduxNotifier<ServerState> {
  final HomePageController _homePageController;
  final TracingService _eventService;

  InspectorServer(this._homePageController, this._eventService);

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

class StartServerAction extends AsyncReduxAction<InspectorServer, ServerState>
    with GlobalActions {
  @override
  Future<ServerState> reduce() async {
    var handler = webSocketHandler((WebSocketChannel webSocket) async {
      dispatch(_SetSinkAction(sink: webSocket.sink));
      webSocket.stream.listen((message) {
        global.dispatch(_HandleClientMessageAction(message: message));
      }, onDone: () {
        dispatch(_ClientDisconnectedAction());
      });
    });

    final server = await shelf_io.serve(handler, '0.0.0.0', 9253);
    _logger.info('Serving at ws://${server.address.host}:${server.port}');
    return state.copyWith(
      running: true,
    );
  }
}

/// Sets the [sink] of the server.
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

  @override
  void after() {
    external(notifier._homePageController).dispatch(RefreshPageController());
  }
}

/// Marks the client as disconnected.
/// Also clears the list of events.
class _ClientDisconnectedAction
    extends ReduxAction<InspectorServer, ServerState> {
  @override
  ServerState reduce() {
    return state.copyWith(
      clientConnected: false,
    );
  }

  @override
  void after() {
    external(notifier._eventService).dispatch(ClearEventsAction());
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

class _HandleClientMessageAction extends GlobalAction {
  final dynamic message;

  _HandleClientMessageAction({
    required this.message,
  });

  @override
  void reduce() {
    final json = jsonDecode(message) as Map<String, dynamic>;
    final type = InspectorClientMessageType.values
        .firstWhere((t) => t.name == json['type']);
    final payload = json['payload'];

    switch (type) {
      case InspectorClientMessageType.hello:
        final events = payload['events'] as List<dynamic>?;
        final graph = payload['graph'] as List<dynamic>;
        final actions = payload['actions'] as Map<String, dynamic>;
        final theme = payload['theme'] as String;
        if (events != null) {
          ref
              .redux(eventTracingProvider)
              .dispatch(InitEventsAction(events: events));
        }
        ref.redux(actionProvider).dispatch(SetActionsAction(actions: actions));
        ref.redux(graphProvider).dispatch(SetGraphAction(nodes: graph));
        ref.redux(settingsProvider).dispatch(SettingsThemeModeAction(
            themeMode: ThemeMode.values.firstWhere((t) => t.name == theme)));
        ref.redux(serverProvider).dispatch(_ClientConnectedAction());
        break;
      case InspectorClientMessageType.event:
        final events = payload['events'] as List<dynamic>;
        ref
            .redux(eventTracingProvider)
            .dispatch(AddEventsAction(events: events));
        break;
      case InspectorClientMessageType.graph:
        final graph = payload['graph'] as List<dynamic>;
        ref.redux(graphProvider).dispatch(SetGraphAction(nodes: graph));
        break;
    }
  }
}
