import 'package:flutter/material.dart';
import 'package:riverpie/src/notifier/rebuildable.dart';

/// A helper class for unit tests.
/// Use this in combination with [RiverpieHistoryObserver].
///
/// This allows for equality of [ElementRebuildable] == [WidgetRebuildable]
/// because it is hard to access the [BuildContext] of a [Widget].
class WidgetRebuildable<W extends Widget> extends Rebuildable {
  @override
  String get debugLabel => throw UnimplementedError();

  @override
  bool get disposed => throw UnimplementedError();

  @override
  void rebuild() => throw UnimplementedError();

  Type get widgetType => W;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WidgetRebuildable && widgetType == other.widgetType) ||
        (other is ElementRebuildable &&
            other.element.target?.widget.runtimeType == widgetType);
  }

  @override
  int get hashCode => widgetType.hashCode;
}
