// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:refena/refena.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/base_notifier.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/listener.dart';

// ignore: implementation_imports
import 'package:refena/src/provider/base_provider.dart';

// ignore: implementation_imports
import 'package:refena/src/provider/watchable.dart';

// ignore: implementation_imports
import 'package:refena/src/ref.dart';
import 'package:refena_flutter/src/element_rebuildable.dart';
import 'package:refena_flutter/src/get_scope.dart';

extension ContextRefExt on BuildContext {
  static final _refCollection = Expando<WatchableRef>();

  /// Access the [Ref] using this [BuildContext].
  WatchableRef get ref {
    return _refCollection[this] ??= WatchableRefImpl(
      container: getContainer(this),
      rebuildable: ElementRebuildable(this as Element),
    );
  }

  /// Shorthand for `context.ref.read()`.
  /// See [Ref.read] for more information.
  R read<N extends BaseNotifier<T>, T, R>(BaseWatchable<N, T, R> watchable) {
    return ref.read(watchable);
  }

  /// Shorthand for `context.ref.watch()`.
  /// See [WatchableRef.watch] for more information.
  R watch<N extends BaseNotifier<T>, T, R>(
    BaseWatchable<N, T, R> watchable, {
    ListenerCallback<T>? listener,
    bool Function(T prev, T next)? rebuildWhen,
  }) {
    return ref.watch(
      watchable,
      listener: listener,
      rebuildWhen: rebuildWhen,
    );
  }

  /// Shorthand for `context.ref.notifier()`.
  /// See [Ref.notifier] for more information.
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    return ref.notifier(provider);
  }

  /// Shorthand for `context.ref.redux()`.
  /// See [Ref.redux] for more information.
  Dispatcher<N, T> redux<N extends ReduxNotifier<T>, T>(
    ReduxProvider<N, T> provider,
  ) {
    return ref.redux(provider);
  }

  /// Shorthand for `context.ref.dispose()`.
  /// See [Ref.dispose] for more information.
  void dispose<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    ref.dispose(provider);
  }

  /// Shorthand for `context.ref.dispatch()`.
  /// See [GlobalActionExtension.dispatch] for more information.
  R dispatch<R>(GlobalActionWithResult<R> action) {
    return ref.dispatch(action);
  }

  /// Shorthand for `context.ref.dispatchAsync()`.
  /// See [GlobalActionExtension.dispatchAsync] for more information.
  Future<R> dispatchAsync<R>(AsyncGlobalActionWithResult<R> action) {
    return ref.dispatchAsync(action);
  }
}
