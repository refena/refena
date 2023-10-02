import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:refena/refena.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/rebuildable.dart';
import 'package:refena_flutter/src/consumer.dart';
import 'package:refena_flutter/src/widget_rebuildable.dart';

/// A [Rebuildable] that rebuilds an [Element].
@internal
// ignore: invalid_use_of_internal_member
class ElementRebuildable extends Rebuildable {
  /// The element to rebuild.
  /// We don't want to increase the time to garbage collect the element.
  final WeakReference<Element> element;

  /// We need to store the debug label because the element might be disposed
  @override
  final String debugLabel;

  ElementRebuildable(Element element)
      : element = WeakReference(element),
        debugLabel = _getDebugLabel(element.widget);

  @override
  void rebuild(ChangeEvent? changeEvent, RebuildEvent? rebuildEvent) {
    element.target?.markNeedsBuild();
  }

  /// Whether this [Rebuildable] is disposed and should be removed.
  /// Either this [Element] is garbage collected or the widget is disposed.
  @override
  bool get disposed => (element.target?.mounted ?? false) == false;

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
    return 'ElementRebuildable<${element.target?.widget.runtimeType}>($debugLabel)';
  }
}

String _getDebugLabel(Widget? widget) {
  return switch (widget) {
    Consumer() => widget.debugLabel,
    ExpensiveConsumer() => widget.debugLabel,
    _ => widget.runtimeType.toString(),
  };
}
