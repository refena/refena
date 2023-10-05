// ignore_for_file: invalid_use_of_internal_member

// ignore: implementation_imports, depend_on_referenced_packages
import 'package:refena/src/tools/tracing_input_model.dart';
import 'package:refena_flutter/refena_flutter.dart';

class TracingState {
  final List<InputEvent> events;
  final bool hasTracing;

  TracingState({
    required this.events,
    required this.hasTracing,
  });

  TracingState copyWith({
    List<InputEvent>? events,
    bool? hasTracing,
  }) {
    return TracingState(
      events: events ?? this.events,
      hasTracing: hasTracing ?? this.hasTracing,
    );
  }

  @override
  String toString() {
    return 'TracingState(events: ${events.length}, hasTracing: $hasTracing)';
  }
}

final eventsProvider = ReduxProvider<TracingService, TracingState>((ref) {
  return TracingService();
});

class TracingService extends ReduxNotifier<TracingState> {
  @override
  TracingState init() => TracingState(
        events: [],
        hasTracing: false,
      );
}

class AddEventsAction extends ReduxAction<TracingService, TracingState> {
  final List<dynamic> events;

  AddEventsAction({
    required this.events,
  });

  @override
  TracingState reduce() {
    final List<InputEvent> newList = [
      ...state.events,
      ...events.map((e) => InputEvent.fromJson(e)),
    ];

    if (newList.length > 200) {
      newList.removeRange(0, newList.length - 200);
    }

    return state.copyWith(
      events: newList.toList(),
      hasTracing: true,
    );
  }
}

class ClearEventsAction extends ReduxAction<TracingService, TracingState> {
  @override
  TracingState reduce() {
    return state.copyWith(
      events: [],
    );
  }
}
