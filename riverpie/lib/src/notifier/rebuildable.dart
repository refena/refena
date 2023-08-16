import 'package:meta/meta.dart';

/// Something that can be rebuilt.
@internal
abstract class Rebuildable {
  /// Schedule a rebuild (in the next frame).
  void rebuild();

  /// Whether this [Rebuildable] is disposed and should be removed.
  bool get disposed;

  /// A debug label for this [Rebuildable].
  String get debugLabel;
}
