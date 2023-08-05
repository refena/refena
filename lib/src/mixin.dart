import 'package:flutter/material.dart';
import 'package:riverpie/src/widget/scope.dart';
import 'package:riverpie/src/ref.dart';

mixin Riverpie<W extends StatefulWidget> on State<W> {
  /// Access this ref inside your [State].
  late final ref = WatchableRef(
    root: _getScope(context),
    state: this,
  );

  /// Call this method inside [initState] to have some
  /// initializations run after the first frame.
  /// The [ref] will be available in the callback.
  ///
  /// This is entirely optional but has some nice side effects
  /// that you can even use [ref] in [State.dispose] because [ref] is
  /// guaranteed to be initialized.
  void ensureRef([void Function()? callback]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref;
      callback?.call();
    });
  }
}

/// Returns the nearest [RiverpieScope].
RiverpieScope _getScope(BuildContext context) {
  final scope = context.dependOnInheritedWidgetOfExactType<RiverpieScope>();
  if (scope == null) {
    throw Exception('Wrap your app with RiverpieScope');
  }
  return scope;
}
