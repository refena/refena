import 'package:meta/meta.dart';

/// A simple class that provides the current time in microseconds
/// without creating [DateTime] objects.
@internal
class TimeProvider {
  final _start = DateTime.now().microsecondsSinceEpoch;
  final _stopwatch = Stopwatch()..start();

  /// Returns the current time in microseconds since epoch.
  int getMicrosSinceEpoch() => _stopwatch.elapsedMicroseconds + _start;
}
