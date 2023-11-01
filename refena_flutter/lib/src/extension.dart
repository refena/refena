import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:refena/src/ref.dart';
import 'package:refena_flutter/src/element_rebuildable.dart';
import 'package:refena_flutter/src/get_scope.dart';

extension ContextRefExt on BuildContext {
  static final _refCollection = Expando<WatchableRef>();

  /// Access the [Ref] using this [BuildContext].
  WatchableRef get ref {
    return _refCollection[this] ??= WatchableRefImpl(
      ref: getScope(this),
      rebuildable: ElementRebuildable(this as Element),
    );
  }
}
