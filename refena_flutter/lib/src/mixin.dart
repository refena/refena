import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:refena/src/ref.dart';
import 'package:refena_flutter/src/extension.dart';

mixin Refena<W extends StatefulWidget> on State<W> {
  /// Access this ref inside your [State].
  late final WatchableRef ref = context.ref;

  /// Call this method inside [initState] to have some
  /// initializations run after the first frame.
  /// The [ref] (without watch) will be available in the callback.
  ///
  /// This is entirely optional but has some nice side effects
  /// that you can even use [ref] in [State.dispose] because [ref] is
  /// guaranteed to be initialized.
  void ensureRef([void Function(Ref ref)? callback]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref; // ignore: unnecessary_statements
      callback?.call(ref);
    });
  }
}
