// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:refena/refena.dart';
// ignore: implementation_imports
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena_flutter/src/element_rebuildable.dart';

/// A helper class for unit tests.
/// Use this in combination with [RefenaHistoryObserver].
///
/// This allows for equality of [ElementRebuildable] == [WidgetRebuildable]
/// because it is hard to access the [BuildContext] of a [Widget].
class WidgetRebuildable<W extends Widget> implements Rebuildable {
  @override
  String get debugLabel => 'WidgetRebuildable<$W>';

  @override
  bool get disposed => throw UnimplementedError();

  @override
  void onDisposeWidget() => throw UnimplementedError();

  @override
  void notifyListenerTarget(BaseNotifier notifier) =>
      throw UnimplementedError();

  @override
  void rebuild(ChangeEvent? changeEvent, RebuildEvent? rebuildEvent) {
    throw UnimplementedError();
  }

  @override
  bool get isWidget => true;

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
