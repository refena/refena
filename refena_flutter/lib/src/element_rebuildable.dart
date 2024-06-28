// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:refena/refena.dart';
// ignore: implementation_imports
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena_flutter/src/test/widget_rebuildable.dart';
import 'package:refena_flutter/src/util/batched_set_controller.dart';
import 'package:refena_flutter/src/widgets/consumer.dart';
import 'package:refena_flutter/src/widgets/family_view_model_builder.dart';
import 'package:refena_flutter/src/widgets/view_model_builder.dart';

@internal
@visibleForTesting
bool printWarning = true;

@internal
@visibleForTesting
int warningCount = 0;

/// A [Rebuildable] that rebuilds an [Element].
@internal
class ElementRebuildable implements Rebuildable {
  /// The element to rebuild.
  /// We don't want to increase the time to garbage collect the element.
  final WeakReference<Element> element;

  /// We need to store the debug label because the element might be disposed
  @override
  final String debugLabel;

  late final _unwatchManager = UnwatchManager(this);

  ElementRebuildable(Element element)
      : element = WeakReference(element),
        debugLabel = _getDebugLabel(element.widget);

  @override
  void rebuild(ChangeEvent? changeEvent, RebuildEvent? rebuildEvent) {
    element.target?.markNeedsBuild();
  }

  /// Whether this [Rebuildable] is disposed and should be removed.
  /// This is the case when
  /// either this [element] is garbage collected or the widget is disposed.
  @override
  bool get disposed => (element.target?.mounted ?? false) == false;

  @override
  void onDisposeWidget() {
    _unwatchManager.dispose();
  }

  /// While we don't interfere with the garbage collection of the [Element],
  /// we need to make sure that the [UnwatchManager] is disposed also.
  /// This boolean is exposed for testing.
  @visibleForTesting
  bool get unwatchManagerDisposed => _unwatchManager._controller.disposed;

  @override
  void notifyListenerTarget(BaseNotifier notifier) {
    _unwatchManager.addNotifier(notifier);
  }

  @override
  bool get isWidget => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ElementRebuildable && identical(element, other.element)) ||
      (other is WidgetRebuildable &&
          element.target?.widget.runtimeType == other.widgetType);

  @override
  int get hashCode => element.hashCode;

  @override
  String toString() {
    return 'ElementRebuildable<${disposed ? 'disposed' : element.target?.widget.runtimeType}>($debugLabel)';
  }
}

/// Responsible for **un**watching [BaseNotifier]s.
/// We use the fact that the widget's build method is synchronous.
/// This allows us to unwatch notifiers in the next microtask because until
/// then all watch directives are executed.
///
/// [ViewProvider]s and [WatchAction]s use a more straightforward approach
/// because they control the build method's execution.
@internal
class UnwatchManager {
  final ElementRebuildable _rebuildable;
  final _controller = BatchedSetController<BaseNotifier>();
  Set<BaseNotifier> _oldNotifiers = const {};

  UnwatchManager(this._rebuildable) {
    _controller.stream.listen((Set<BaseNotifier> newNotifiers) {
      if (_oldNotifiers.isNotEmpty) {
        // Find old notifiers that are not in the new notifiers.
        final removedNotifiers = _oldNotifiers.difference(newNotifiers);
        for (final notifier in removedNotifiers) {
          notifier.removeListener(_rebuildable);
        }
      }

      _oldNotifiers = newNotifiers;
    });
  }

  void addNotifier(BaseNotifier notifier) {
    _controller.schedule(notifier);

    if (kDebugMode &&
        _rebuildable.element.target?.debugDoingBuild == false &&
        _rebuildable.element.target?.widget is! ConstrainedLayoutBuilder) {
      warningCount++;

      if (printWarning) {
        print('''
$_red[Refena] In ${_rebuildable.debugLabel}, ${notifier.debugLabel} is watched outside the build method! This will lead to inconsistent rebuilds of the widget. Use context.read or ref.read instead.$_reset''');
        print('''
$_red[Refena] A non-breaking stacktrace will be printed for easier debugging:$_reset\n${StackTrace.current}''');
      }
      return;
    }

    // Apparently, this is not possible to detect.
    // Flutter may rebuild a widget multiple times synchronously.
    // This is okay.

//     if (!scheduled) {
//       print('''
// $_red[Refena] In ${_rebuildable.debugLabel}, ${notifier.debugLabel} is watched multiple times! Only watch each provider once in a build method. Tip: Use records to combine multiple fields.$_reset''');
//       print('''
// $_red[Refena] A non-breaking stacktrace will be printed for easier debugging:$_reset\n${StackTrace.current}''');
//     }
  }

  void dispose() {
    _controller.dispose();
    _oldNotifiers = const {};
  }
}

String _getDebugLabel(Widget? widget) {
  return switch (widget) {
    Consumer() => widget.debugLabel,
    ExpensiveConsumer() => widget.debugLabel,
    ViewModelBuilder() => widget.debugLabel,
    FamilyViewModelBuilder() => widget.debugLabel,
    _ => widget.runtimeType.toString(),
  };
}

const _red = '\x1B[31m';
const _reset = '\x1B[0m';
