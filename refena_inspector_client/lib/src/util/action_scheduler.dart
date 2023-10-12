import 'dart:async';

import 'package:meta/meta.dart';
// ignore: implementation_imports
import 'package:refena/src/util/time_provider.dart';

final _timeProvider = TimeProvider();

/// Ensures that the [action] is executed at most once every [minDelay].
/// If [scheduleAction] is called multiple times in a short period of time,
/// the action will be executed only once after the delay.
@internal
class ActionScheduler {
  /// The minimum delay between two actions.
  final Duration minDelay;

  /// The maximum delay between two actions.
  /// i.e. [action] will be executed if [scheduleAction] is not called
  /// for [maxDelay] milliseconds.
  final Duration maxDelay;

  /// The action that will be executed when [scheduleAction] is called.
  final void Function() action;

  /// The last time when the [action] was executed.
  int _lastActionTime = 0;

  /// The timestamp of the last call delayed schedule.
  int _delayedTimestamp = 0;

  late Timer _timer;

  ActionScheduler({
    required this.minDelay,
    required this.maxDelay,
    required this.action,
  }) : assert(minDelay < maxDelay) {
    _timer = Timer.periodic(maxDelay, (_) {
      final now = _timeProvider.getMillisSinceEpoch();
      if (now - _lastActionTime > maxDelay.inMilliseconds) {
        _lastActionTime = now;
        action();
      }
    });
  }

  void scheduleAction() {
    final now = _timeProvider.getMillisSinceEpoch();
    _schedule(now, initialCall: true);
  }

  void _schedule(int timestamp, {required bool initialCall}) {
    if (!initialCall && _delayedTimestamp != timestamp) {
      return;
    }

    final now = _timeProvider.getMillisSinceEpoch();
    if (now - _lastActionTime < minDelay.inMilliseconds) {
      if (!initialCall || _delayedTimestamp == timestamp) {
        return;
      }
      _delayedTimestamp = timestamp;
      Future.delayed(minDelay, () => _schedule(timestamp, initialCall: false));
      return;
    }

    _lastActionTime = now;
    action();
  }

  void reset() {
    _lastActionTime = 0;
    _delayedTimestamp = 0;
  }

  void dispose() {
    _timer.cancel();
  }
}
