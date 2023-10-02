import 'package:flutter/material.dart';
import 'package:refena/refena.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/rebuildable.dart';
import 'package:refena_flutter/src/element_rebuildable.dart';

/// A helper class for unit tests.
/// Use this in combination with [RefenaHistoryObserver].
///
/// This allows for equality of [ElementRebuildable] == [WidgetRebuildable]
/// because it is hard to access the [BuildContext] of a [Widget].
// ignore: invalid_use_of_internal_member
class WidgetRebuildable<W extends Widget> extends Rebuildable {
  @override
  String get debugLabel => 'WidgetRebuildable<$W>';

  @override
  bool get disposed => throw UnimplementedError();

  @override
  void rebuild(ChangeEvent? changeEvent, RebuildEvent? rebuildEvent) {
    throw UnimplementedError();
  }

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
