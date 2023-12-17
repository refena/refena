// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena_flutter/src/view_model_builder.dart';

/// Provides a [BuildContext] inside a [BaseNotifier].
/// It binds the lifetime of the [BaseNotifier] to a [BuildContext].
/// This allows you to write controllers using [Notifier]s or [ReduxNotifier]s.
///
/// Adding the mixin alone is not enough:
/// You need to access the provider within a [ViewModelBuilder].
/// By **not** doing so, you will get an error.
mixin ViewBuildContext<T> on BaseNotifier<T> {
  WeakReference<BuildContext>? _context;

  /// Returns the [BuildContext] associated with this notifier.
  @protected
  BuildContext get context {
    final weakRef = _context;
    if (weakRef == null) {
      throw StateError(
        'BuildContext is not initialized. Use ViewModelBuilder.',
      );
    }
    final context = weakRef.target;
    if (context == null || !context.mounted) {
      throw StateError('BuildContext is already disposed.');
    }
    return context;
  }

  /// A nullable version of [context] that does not throw.
  @protected
  BuildContext? get contextOrNull {
    final context = _context?.target;
    if (context == null || !context.mounted) {
      return null;
    }
    return context;
  }

  @internal
  @override
  bool get requireBuildContext => true;
}

@internal
extension ViewBuildContextExtension<T> on ViewBuildContext<T> {
  void setContext(BuildContext context) {
    _context = WeakReference(context);
  }
}
