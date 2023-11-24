// ignore_for_file: invalid_use_of_internal_member

// ignore: implementation_imports
import 'package:refena/src/tools/tracing_input_model.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// The state of the event tracing.
/// [hasTracing] is true if tracing is enabled.
class TracingState {
  final List<InputEvent> events;

  /// The running actions.
  /// Mutable for performance reasons.
  /// Event Id -> Event
  final Map<int, InputEvent> runningActions;

  /// The historical actions.
  /// Mutable for performance reasons.
  /// Action Name -> ActionInfo
  final Map<String, ActionInfo> historicalActions;

  final bool hasTracing;
  final bool hasFinishedEvents;

  /// The delay in milliseconds between the client and the server.
  /// This is used to calculate the correct duration of the running actions.
  final int clientDelay;

  TracingState({
    required this.events,
    required this.runningActions,
    required this.historicalActions,
    required this.hasTracing,
    required this.hasFinishedEvents,
    required this.clientDelay,
  });

  TracingState copyWith({
    List<InputEvent>? events,
    Map<int, InputEvent>? runningActions,
    Map<String, ActionInfo>? historicalActions,
    bool? hasTracing,
    bool? hasFinishedEvents,
    int? clientDelay,
  }) {
    return TracingState(
      events: events ?? this.events,
      runningActions: runningActions ?? this.runningActions,
      historicalActions: historicalActions ?? this.historicalActions,
      hasTracing: hasTracing ?? this.hasTracing,
      hasFinishedEvents: hasFinishedEvents ?? this.hasFinishedEvents,
      clientDelay: clientDelay ?? this.clientDelay,
    );
  }

  @override
  String toString() {
    return 'EventState(events: ${events.length}, hasTracing: $hasTracing)';
  }
}

class ActionInfo {
  int successCount;
  int errorCount;

  /// The average time in milliseconds.
  int avgTime;

  /// The latest time in milliseconds.
  int latestTime;

  ActionInfo({
    required this.successCount,
    required this.errorCount,
    required this.avgTime,
    required this.latestTime,
  });
}

final eventTracingProvider = ReduxProvider<TracingService, TracingState>((ref) {
  return TracingService();
});

class TracingService extends ReduxNotifier<TracingState> {
  @override
  TracingState init() => TracingState(
        events: [],
        runningActions: {},
        historicalActions: {},
        hasTracing: false,
        hasFinishedEvents: false,
        clientDelay: 0,
      );
}

/// Initializes the list of [events].
class InitEventsAction extends ReduxAction<TracingService, TracingState> {
  final List<dynamic> events;

  InitEventsAction({
    required this.events,
  });

  @override
  TracingState reduce() {
    final initialEvents = events.map((e) => InputEvent.fromJson(e)).toList();
    _addActionsToMap(
      events: initialEvents,
      runningActions: {},
      historicalActions: {},
    );
    return state.copyWith(
      events: initialEvents,
      hasTracing: true,
      hasFinishedEvents:
          initialEvents.any((e) => e.type == InputEventType.actionFinished),
    );
  }
}

/// Adds the [events] to the list of events.
/// If the list is longer than 200 items,
/// the oldest items are removed.
class AddEventsAction extends ReduxAction<TracingService, TracingState> {
  final List<dynamic> events;

  AddEventsAction({
    required this.events,
  });

  @override
  TracingState reduce() {
    final newEvents = events.map((e) => InputEvent.fromJson(e)).toList();

    _addActionsToMap(
      events: newEvents,
      runningActions: state.runningActions,
      historicalActions: state.historicalActions,
    );

    final List<InputEvent> newList = [
      ...state.events,
      ...newEvents,
    ];

    if (newList.length > 200) {
      newList.removeRange(0, newList.length - 200);
    }

    print('delay: ${state.clientDelay} ms');

    return state.copyWith(
      events: newList,
      hasFinishedEvents: state.hasFinishedEvents ||
          newList.any((e) => e.type == InputEventType.actionFinished),
      clientDelay: state.clientDelay != 0
          ? state.clientDelay
          : DateTime.now().millisecondsSinceEpoch -
              newList.last.millisSinceEpoch,
    );
  }
}

/// Clears the list of events.
class ClearEventsAction extends ReduxAction<TracingService, TracingState> {
  @override
  TracingState reduce() {
    return state.copyWith(
      events: [],
    );
  }
}

const _alpha = 0.1;

void _addActionsToMap({
  required List<InputEvent> events,
  required Map<int, InputEvent> runningActions,
  required Map<String, ActionInfo> historicalActions,
}) {
  for (final event in events) {
    if (event.type == InputEventType.actionDispatched) {
      runningActions[event.actionId!] = event;
    } else if (event.type == InputEventType.actionFinished ||
        event.type == InputEventType.actionError) {
      final removedEvent = runningActions.remove(event.actionId);

      if (removedEvent != null) {
        final existing = historicalActions[removedEvent.fullLabel];
        final success = event.type == InputEventType.actionFinished;
        ActionInfo info;
        if (existing == null) {
          info = ActionInfo(
            successCount: success ? 1 : 0,
            errorCount: success ? 0 : 1,
            avgTime: event.millisSinceEpoch - removedEvent.millisSinceEpoch,
            latestTime: removedEvent.millisSinceEpoch,
          );
          historicalActions[removedEvent.fullLabel] = info;
        } else {
          info = existing;
          if (success) {
            info.successCount++;
          } else {
            info.errorCount++;
          }
          info.latestTime = removedEvent.millisSinceEpoch;
        }

        // Update EMA
        info.avgTime = (info.avgTime * (1 - _alpha) +
                (event.millisSinceEpoch - removedEvent.millisSinceEpoch) *
                    _alpha)
            .toInt();
      }
    }
  }
}

extension on InputEvent {
  String get fullLabel {
    return '${data['Action Group']}.$label';
  }
}
