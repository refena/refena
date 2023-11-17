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

  late ActionScheduler _eventsScheduler;
  late ActionScheduler _graphScheduler;
  List<RefenaEvent> _unsentEvents = [];
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
  void init() {
    _eventsScheduler = ActionScheduler(
      minDelay: minDelay,
      maxDelay: const Duration(hours: 999),
      action: () {
        final events = _unsentEvents;
        _unsentEvents = [];
        _controller?.sendEvents(events);
      },
    );

    final tracingObserver = _findTracingObserver(ref.container.observer);
    tracingObserver?.listeners.add((event) {
      _unsentEvents.add(event);
      _eventsScheduler.scheduleAction();
    });

    _graphScheduler = ActionScheduler(
      minDelay: minDelay,
      maxDelay: maxDelay,
      action: () => _controller?.sendGraph(),
    );
    _runLoop();
  }

  @override
  void handleEvent(RefenaEvent event) {
    _graphScheduler.scheduleAction();
  }

  Future<void> _runLoop() async {
    await Future.delayed(Duration(seconds: 1));

    int run = 0;
    final List<String> hosts;
    if (host != null) {
      hosts = [host!];
      ref.message('Connecting to Refena Inspector at $host:$port...');
    } else {
      hosts = [
        if (ref.container.platformHint == PlatformHint.unknown ||
            ref.container.platformHint == PlatformHint.android)
          // Android emulator
          // Also need to assume if unknown because the initialization of the
          // RefenaScope might be too late (e.g. explicit container).
          '10.0.2.2',
        'localhost',
      ];
      ref.message(
          'Connecting to Refena Inspector at [${hosts.map((h) => h).join('|')}]:$port (inferred by platformHint = ${ref.container.platformHint.name})...');
    }

    int hostIndex = 0;
    while (true) {
      final result = await runWebSocket(hosts[hostIndex]);
      if (result) {
        run = 1;
      } else {
        run++;
      }

      if (run == 1) {
        ref.message('Failed to connect to Refena Inspector.');
      }
      final sleepSeconds = switch (run) {
        < 10 => 1,
        < 100 => 3,
        _ => 5,
      };
      await Future.delayed(Duration(seconds: sleepSeconds));

      hostIndex = (hostIndex + 1) % hosts.length;
    }
  }

  /// Connects to the inspector server.
  /// Returns true if the closed connection was successful.
  /// Returns false if the connection failed.
  Future<bool> runWebSocket(String host) async {
    try {
      final wsUrl = Uri(scheme: 'ws', host: host, port: port);
      var channel = WebSocketChannel.connect(wsUrl);

      // https://github.com/dart-lang/web_socket_channel/issues/249
      await channel.ready;

      _controller = WebSocketController(
        ref: ref,
        sink: channel.sink,
        stream: channel.stream,
        actions: actions,
        theme: theme,
        errorParser: errorParser,
      );

      // drop events scheduled before the connection was established
      _unsentEvents.clear();
      _eventsScheduler.reset();

      await _controller?.handleMessages();
      return true;
    } catch (e) {
      return false;
    } finally {
      _controller = null;
    }
  }
}

/// Recursively finds the [RefenaTracingObserver] in the given [observer].
RefenaTracingObserver? _findTracingObserver(RefenaObserver? observer) {
  if (observer is RefenaTracingObserver) {
    return observer;
  }

  if (observer is RefenaMultiObserver) {
    for (final o in observer.observers) {
      final result = _findTracingObserver(o);
      if (result != null) {
        return result;
      }
    }
  }

  return null;
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
  String get debugLabel => 'InspectorAction($name)';

  @override
  String toString() => 'InspectorAction(name: $name, params: $params)';
}
