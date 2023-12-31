import 'package:refena/src/action/redux_action.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/observer/event.dart';
import 'package:refena/src/provider/types/view_provider.dart';
import 'package:refena/src/ref.dart';
import 'package:refena/src/reference.dart';

/// Something that can be rebuilt.
/// It might be
/// - a [BuildContext],
/// - a notifier (e.g. from a [ViewProvider]), or
/// - a [WatchAction].
///
/// A [WatchableRef] holds a [Rebuildable] to make [WatchableRef.watch] work.
abstract interface class Rebuildable implements LabeledReference {
  /// Schedule a rebuild (in the next frame).
  /// Optionally pass the [changeEvent], or [rebuildEvent]
  /// that triggered the rebuild.
  /// The event is consumed by the [ViewProviderNotifier] that
  /// fires the [RebuildEvent].
  void rebuild(ChangeEvent? changeEvent, RebuildEvent? rebuildEvent);

  /// Whether this [Rebuildable] is disposed and should be removed.
  bool get disposed;

  /// Only for [ElementRebuildable]. Noop for others.
  /// Allows for further cleanup logic.
  void onDisposeWidget();

  /// Only for [ElementRebuildable]. Noop for others.
  /// Notifies that a new [BaseNotifier] is being listened.
  /// This should be called within a build method so it can unwatch
  /// old notifiers in the next microtask.
  void notifyListenerTarget(BaseNotifier notifier);

  /// A debug label for this [Rebuildable].
  @override
  String get debugLabel;

  /// Whether this [Rebuildable] is an [ElementRebuildable].
  /// This is a workaround for the fact that
  /// [ElementRebuildable] is in refena_flutter so we cannot refer it from here.
  bool get isWidget;
}
