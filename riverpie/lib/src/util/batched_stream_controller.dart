import 'dart:async';

/// A stream controller that batches multiple calls to [schedule]
/// into a single event.
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
