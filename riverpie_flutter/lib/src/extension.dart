import 'package:flutter/material.dart';
import 'package:riverpie/riverpie.dart';
import 'package:riverpie_flutter/src/element_rebuildable.dart';
import 'package:riverpie_flutter/src/get_scope.dart';

extension ContextRefExt on BuildContext {
  static final _refCollection = Expando<WatchableRef>();

  /// Access the [Ref] using this [BuildContext].
  WatchableRef get ref {
    return _refCollection[this] ??= WatchableRef(
      ref: getScope(this),
      rebuildable: ElementRebuildable(this as Element),
    );
  }
}
