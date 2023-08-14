import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/src/widget/consumer.dart';

/// Something that can be rebuilt.
@internal
abstract class Rebuildable {
  /// Trigger a rebuild (in the next frame).
  void rebuild();

  /// Whether this [Rebuildable] is disposed and should be removed.
  bool get disposed;

  /// A debug label for this [Rebuildable].
  String get debugLabel;
}

/// A [Rebuildable] that rebuilds an [Element].
@internal
class ElementRebuildable extends Rebuildable {
  final Element element;

  ElementRebuildable(this.element);

  @override
  void rebuild() {
    element.markNeedsBuild();
  }

  @override
  bool get disposed => !element.mounted;

  @override
  String get debugLabel {
    final widget = element.widget;
    if (widget is ExpensiveConsumer) {
      return widget.debugLabel;
    }
    return widget.runtimeType.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementRebuildable && identical(element, other.element);

  @override
  int get hashCode => element.hashCode;
}
