import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/src/widget/consumer.dart';

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

/// A [Rebuildable] that rebuilds an [Element].
@internal
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
  void rebuild() {
    element.target?.markNeedsBuild();
  }

  /// Whether this [Rebuildable] is disposed and should be removed.
  /// Either this [Element] is garbage collected or the widget is disposed.
  @override
  bool get disposed => (element.target?.mounted ?? false) == false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementRebuildable && identical(element, other.element);

  @override
  int get hashCode => element.hashCode;
}

String _getDebugLabel(Widget? widget) {
  if (widget is ExpensiveConsumer) {
    return widget.debugLabel;
  }
  return widget.runtimeType.toString();
}
