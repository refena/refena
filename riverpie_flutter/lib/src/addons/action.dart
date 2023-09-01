// ignore_for_file: invalid_use_of_internal_member

import 'package:riverpie/riverpie.dart';

// ignore: implementation_imports
import 'package:riverpie/src/notifier/base_notifier.dart';

// ignore: implementation_imports
import 'package:riverpie/src/proxy_ref.dart';
import 'package:riverpie_flutter/src/addons/navigation.dart';
import 'package:riverpie_flutter/src/addons/snack_bar.dart';

/// A flag to allow the usage of
/// the [Ref.dispatch] convenience method.
abstract interface class AddonAction<T> {}

abstract interface class AsyncAddonAction<T> extends AddonAction<void> {}

extension AddonActionExtension on Ref {
  /// Dispatches a [AddonAction].
  T dispatch<T>(AddonAction<T> action) {
    return _dispatch(this, action);
  }

  /// Dispatches an [AsyncAddonAction].
  /// Returns the result of the action.
  Future<T?> dispatchAsync<T>(AsyncAddonAction<T> action) {
    return _dispatchAsync(this, action);
  }
}

mixin AddonActions<N extends BaseReduxNotifier<T>, T, R>
    on BaseReduxAction<N, T, R> {
  /// Access the addon dispatcher.
  late final addon = AddonActionsDispatcher(ProxyRef(
    internalRef!,
    debugLabel,
    this,
  ));
}

class AddonActionsDispatcher {
  final Ref _ref;

  AddonActionsDispatcher(this._ref);

  /// Dispatches a [AddonAction].
  T dispatch<T>(AddonAction<T> action) {
    return _dispatch(_ref, action);
  }

  /// Dispatches an [AsyncAddonAction].
  /// Returns the result of the action.
  Future<T?> dispatchAsync<T>(AsyncAddonAction<T> action) {
    return _dispatchAsync(_ref, action);
  }
}

/// Dispatches a [AddonAction].
T _dispatch<T>(Ref ref, AddonAction<T> action) {
  switch (action) {
    case BaseNavigationPushAction<T> a:
      ref.redux(navigationReduxProvider).dispatchAsyncTakeResult(a);
      return null as T;
    case BaseNavigationPopAction a:
      return ref.redux(navigationReduxProvider).dispatch(a);
    case BaseShowSnackBarAction a:
      return ref.redux(snackBarReduxProvider).dispatch(a);
    default:
      throw ArgumentError('Unknown action: $action');
  }
}

/// Dispatches an [AsyncAddonAction].
/// Returns the result of the action.
Future<T?> _dispatchAsync<T>(Ref ref, AsyncAddonAction<T> action) async {
  return switch (action) {
    BaseNavigationPushAction<T> a =>
      await ref.redux(navigationReduxProvider).dispatchAsyncTakeResult(a),
    _ => throw ArgumentError('Unknown action: $action'),
  };
}
