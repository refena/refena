import 'dart:async';

import 'package:meta/meta.dart';

/// A more specialized version of [BatchedStreamController] that only works
/// with [Set]s.
@internal
class BatchedSetController<T extends Object> {
  final _streamController = StreamController<Set<T>>();
  Set<T>? _scheduledEvents;
  bool _disposed = false;

  /// Schedules an event to be fired on the stream.
  /// In the next microtask, all events are batched into a single event.
  /// Returns true if the event was scheduled, false if it was ignored.
  bool schedule(T data) {
    if (_scheduledEvents != null) {
      return _scheduledEvents!.add(data);
    }

    _scheduledEvents = {data};
    scheduleMicrotask(() {
      _streamController.add(_scheduledEvents!);
      _scheduledEvents = null;
    });
    return true;
  }

  /// Closes the stream and releases resources.
  void dispose() {
    _streamController.close();
    _scheduledEvents = null;
    _disposed = true;
  }

  /// Whether this controller has been disposed.
  bool get disposed => _disposed;

  Stream<Set<T>> get stream => _streamController.stream;
}
