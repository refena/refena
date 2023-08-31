import 'dart:collection';

import 'package:riverpie/src/notifier/types/change_notifier.dart';
import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/types/change_notifier_provider.dart';

/// A more sophisticated version of [RiverpieHistoryObserver].
/// This should be used in combination with [RiverpieTracingPage].
class RiverpieTracingObserver extends RiverpieObserver {
  /// The maximum number of events to store.
  final int limit;

  /// If true, then [ListenerAddedEvent] and [ListenerRemovedEvent] are
  /// also included in the list of events.
  final bool includeListenerEvents;

  /// If the given function returns `true`, then the event
  /// won't be logged.
  final bool Function(RiverpieEvent event)? exclude;

  RiverpieTracingObserver({
    this.limit = 100,
    this.includeListenerEvents = false,
    this.exclude,
  }) : assert(limit > 0, 'limit must be greater than 0');

  @override
  void init() {
    ref.notifier(tracingProvider)._limit = limit;
    ref.notifier(tracingProvider)._initialized = true;
  }

  @override
  void handleEvent(RiverpieEvent event) {
    if (!includeListenerEvents &&
        (event is ListenerAddedEvent || event is ListenerRemovedEvent)) {
      return;
    }

    if (exclude != null && exclude!(event)) {
      return;
    }

    ref.notifier(tracingProvider)._addEvent(event);
  }
}

final tracingProvider = ChangeNotifierProvider((ref) {
  return TracingNotifier();
});

class TracingNotifier extends ChangeNotifier {
  int _limit = 100;
  bool _initialized = false;
  final Queue<RiverpieEvent> events = Queue();

  bool get initialized => _initialized;

  void _addEvent(RiverpieEvent event) {
    events.add(event);

    if (events.length > _limit) {
      events.removeFirst();
    }

    // Do not fire notifyListeners as we don't want to interfere with the
    // library consumer.
    // This would essentially emit a new event which would be added to the
    // list of events.
  }

  void clear() {
    events.clear();
  }
}
