import 'dart:collection';

import 'package:refena/src/notifier/types/change_notifier.dart';
import 'package:refena/src/observer/event.dart';
import 'package:refena/src/observer/observer.dart';
import 'package:refena/src/provider/types/change_notifier_provider.dart';

/// A more sophisticated version of [RefenaHistoryObserver].
/// This should be used in combination with [RefenaTracingPage].
class RefenaTracingObserver extends RefenaObserver {
  /// The maximum number of events to store.
  final int limit;

  /// If the given function returns `true`, then the event
  /// won't be logged.
  final bool Function(RefenaEvent event)? exclude;

  RefenaTracingObserver({
    this.limit = 100,
    this.exclude,
  }) : assert(limit > 0, 'limit must be greater than 0');

  @override
  void init() {
    ref.notifier(tracingProvider)._limit = limit;
    ref.notifier(tracingProvider)._initialized = true;
  }

  @override
  void handleEvent(RefenaEvent event) {
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
  final Queue<RefenaEvent> events = Queue();

  bool get initialized => _initialized;

  void _addEvent(RefenaEvent event) {
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