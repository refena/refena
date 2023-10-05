// ignore_for_file: invalid_use_of_internal_member

// ignore: implementation_imports
import 'package:refena/src/tools/tracing_input_model.dart';
import 'package:refena_flutter/refena_flutter.dart';

class EventState {
  final List<InputEvent> events;
  final bool hasTracing;

  EventState({
    required this.events,
    required this.hasTracing,
  });

  EventState copyWith({
    List<InputEvent>? events,
    bool? hasTracing,
  }) {
    return EventState(
      events: events ?? this.events,
      hasTracing: hasTracing ?? this.hasTracing,
    );
  }

  @override
  String toString() {
    return 'EventState(events: ${events.length}, hasTracing: $hasTracing)';
  }
}

final eventsProvider = ReduxProvider<EventService, EventState>((ref) {
  return EventService();
});

class EventService extends ReduxNotifier<EventState> {
  @override
  EventState init() => EventState(
        events: [],
        hasTracing: false,
      );
}

/// Initializes the list of [events].
class InitEventsAction extends ReduxAction<EventService, EventState> {
  final List<dynamic> events;

  InitEventsAction({
    required this.events,
  });

  @override
  EventState reduce() {
    return state.copyWith(
      events: [
        ...state.events,
        ...events.map((e) => InputEvent.fromJson(e)),
      ],
      hasTracing: true,
    );
  }
}

/// Adds the [events] to the list of events.
/// If the list is longer than 200 items,
/// the oldest items are removed.
class AddEventsAction extends ReduxAction<EventService, EventState> {
  final List<dynamic> events;

  AddEventsAction({
    required this.events,
  });

  @override
  EventState reduce() {
    final List<InputEvent> newList = [
      ...state.events,
      ...events.map((e) => InputEvent.fromJson(e)),
    ];

    if (newList.length > 200) {
      newList.removeRange(0, newList.length - 200);
    }

    return state.copyWith(
      events: newList,
    );
  }
}

/// Clears the list of events.
class ClearEventsAction extends ReduxAction<EventService, EventState> {
  @override
  EventState reduce() {
    return state.copyWith(
      events: [],
    );
  }
}
