import 'package:meta/meta.dart';

/// A simple class that provides an id.
@internal
class IdProvider {
  int _id = 0;

  /// Returns the next id.
  int getNextId() => _id++;
}
