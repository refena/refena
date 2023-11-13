import 'dart:async';

import 'package:meta/meta.dart';

/// A stream controller that batches multiple calls to [schedule]
/// into a single event in the next microtask.
@internal
class BatchedStreamController<T> {
  final _streamController = StreamController<List<T>>();
  List<T>? _scheduledEvents;

  /// Schedules an event to be fired on the stream.
  /// If an event is already scheduled, this call is ignored.
  void schedule(T? data) {
    if (_scheduledEvents != null) {
      if (data != null) {
        _scheduledEvents!.add(data);
      }
      return;
    }

    if (data != null) {
      _scheduledEvents = [data];
    } else {
      _scheduledEvents = [];
    }
    scheduleMicrotask(() {
      if (_streamController.isClosed) {
        // Might be disposed while waiting for the micro task.
        return;
      }
      _streamController.add(_scheduledEvents!);
      _scheduledEvents = null;
    });
  }

  void dispose() {
    _streamController.close();
    _scheduledEvents = null;
  }

  Stream<List<T>> get stream => _streamController.stream;
}
