import 'package:meta/meta.dart';
import 'package:riverpie/riverpie.dart';

/// Something that can be rebuilt.
@internal
abstract class Rebuildable {
  /// Schedule a rebuild (in the next frame).
  /// Optionally pass the [changeEvent], or [rebuildEvent]
  /// that triggered the rebuild.
  /// The event is consumed by the [ViewProviderNotifier] that
  /// fires the [RebuildEvent].
  void rebuild(ChangeEvent? changeEvent, RebuildEvent? rebuildEvent);

  /// Whether this [Rebuildable] is disposed and should be removed.
  bool get disposed;

  /// A debug label for this [Rebuildable].
  String get debugLabel;
}
