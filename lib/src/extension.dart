import 'package:flutter/material.dart';
import 'package:riverpie/src/ref.dart';
import 'package:riverpie/src/util/get_scope.dart';

extension ContextRefExt on BuildContext {
  static final _refCollection = Expando<WatchableRef>();

  /// Access the [Ref] using this [BuildContext].
  WatchableRef get ref {
    return _refCollection[this] ??= WatchableRef.fromElement(
      ref: getScope(this),
      element: this as Element,
    );
  }
}
