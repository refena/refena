import 'dart:async';

/// A stream controller that batches multiple calls to [schedule]
/// into a single event.
class BatchedStreamController {
  final _streamController = StreamController<void>();
  bool _isScheduled = false;

  /// Schedules an event to be fired on the stream.
  /// If an event is already scheduled, this call is ignored.
  void schedule() {
    if (_isScheduled) {
      return;
    }

    _isScheduled = true;
    scheduleMicrotask(() {
      _isScheduled = false;
      _streamController.add(null);
    });
  }

  Stream<void> get stream => _streamController.stream;
}
