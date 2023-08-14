import 'package:flutter/material.dart';
import 'package:riverpie/src/ref.dart';
import 'package:riverpie/src/util/get_scope.dart';

extension ContextRefExt on BuildContext {
  /// Access the [Ref] using this [BuildContext].
  /// If you access multiple providers, you should store the [Ref] into
  /// a local variable inside the build method for better performance.
  /// ... or use the [Riverpie] mixin inside your StatefulWidgets.
  WatchableRef get ref {
    return WatchableRef.fromElement(
      ref: getScope(this),
      element: this as Element,
    );
  }
}
