import 'package:flutter/material.dart';
import 'package:refena/refena.dart';
import 'package:refena_flutter/src/element_rebuildable.dart';
import 'package:refena_flutter/src/get_scope.dart';

mixin Refena<W extends StatefulWidget> on State<W> {
  /// Access this ref inside your [State].
  late final ref = WatchableRefImpl(
    ref: getScope(context),
    rebuildable: ElementRebuildable(context as Element),
  );

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
