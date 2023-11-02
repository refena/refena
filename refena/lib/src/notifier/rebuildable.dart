import 'package:meta/meta.dart';
import 'package:refena/src/action/redux_action.dart';
import 'package:refena/src/observer/event.dart';
import 'package:refena/src/reference.dart';

/// Something that can be rebuilt.
/// It might be a [Widget], a [ViewProvider] or a [WatchAction].
/// A [Ref] holds a [Rebuildable] to make [ref.watch] work.
@internal
abstract class Rebuildable implements LabeledReference {
  /// Schedule a rebuild (in the next frame).
  /// Optionally pass the [changeEvent], or [rebuildEvent]
  /// that triggered the rebuild.
  /// The event is consumed by the [ViewProviderNotifier] that
  /// fires the [RebuildEvent].
  void rebuild(ChangeEvent? changeEvent, RebuildEvent? rebuildEvent);

  /// Whether this [Rebuildable] is disposed and should be removed.
  bool get disposed;

  /// A debug label for this [Rebuildable].
  @override
  String get debugLabel;

  /// Whether this [Rebuildable] is an [ElementRebuildable].
  /// This is a workaround for the fact that
  /// [ElementRebuildable] is in refena_flutter so we cannot refer it from here.
  bool get isWidget;
}
