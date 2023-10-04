import 'dart:async';

import 'package:refena/refena.dart';
import 'package:refena_inspector_client/src/builder/actions_builder.dart';
import 'package:refena_inspector_client/src/inspector_action.dart';
import 'package:refena_inspector_client/src/util/action_scheduler.dart';
import 'package:refena_inspector_client/src/websocket_controller.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// This observer connects to the inspector server
/// and communicates the state of the app.
class RefenaInspectorObserver extends RefenaObserver {
  /// The host of the inspector server.
  /// If null, it will use 'localhost' (and '10.0.2.2' for Android).
  final String? host;

  /// The port of the inspector server.
  final int port;

  /// The action map that will be displayed in the inspector.
  /// It can be nested.
  /// One action can be either a `void Function(Ref)` or an [InspectorAction].
  ///
  /// Example:
  /// actions: {
  ///   'Counter': {
  ///     'Increment': (ref) => ref.read(counterProvider).increment(),
  ///   },
  /// },
  final Map<String, dynamic> actions;

  /// The default theme of the inspector.
  /// We must use string here because the client does not depend on Flutter.
  /// Allowed values: 'light', 'dark', 'system'.
  final String theme;

  /// The minimum delay between two messages.
  final Duration minDelay;

  /// The maximum delay between two graph messages.
  /// By default, the graph is sent if a [RefenaEvent] is emitted.
  /// This maximum delay is used to still keep the graph up-to-date by
  /// sending the graph even if no event is emitted.
  /// The real delay might be higher if the graph does not change.
  final Duration maxDelay;

  /// Parses an error to a map for more a more human-readable format.
  /// This is used by the tracing page to display the error.
  /// Falls back to the default error parser.
  final ErrorParser? errorParser;

  late ActionScheduler _graphScheduler;
  WebSocketController? _controller;

  RefenaInspectorObserver({
    this.host,
    this.port = 9253,
    this.theme = 'system',
    this.minDelay = const Duration(milliseconds: 100),
    this.maxDelay = const Duration(milliseconds: 500),
    this.errorParser,
    Map<String, dynamic> actions = const {},
  }) : actions = ActionsBuilder.normalizeActionMap(actions);

  @override
  void init() async {
    _graphScheduler = ActionScheduler(
      minDelay: minDelay,
      maxDelay: maxDelay,
      action: () => _controller?.sendGraph(),
    );
    while (true) {
      try {
        await runWebSocket();
      } catch (e) {
        print('Failed to connect to refena inspector server.');
        await Future.delayed(Duration(seconds: 3));
      }
    }
  }

  @override
  void handleEvent(RefenaEvent event) {
    _graphScheduler.scheduleAction();
  }

  Future<void> runWebSocket() async {
    final wsUrl = Uri(scheme: 'ws', host: host ?? 'localhost', port: port);
    var channel = WebSocketChannel.connect(wsUrl);

    // https://github.com/dart-lang/web_socket_channel/issues/249
    await channel.ready;

    print('Connected to refena inspector server.');

    _controller = WebSocketController(
      ref: ref,
      sink: channel.sink,
      stream: channel.stream,
      actions: actions,
      theme: theme,
    );

    await _controller?.handleMessages();
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
