import 'package:riverpie/riverpie.dart';
import 'package:riverpie_flutter/src/addons/navigation.dart';
import 'package:riverpie_flutter/src/addons/snack_bar.dart';

/// A flag to allow the usage of
/// the [Ref.dispatch] convenience method.
abstract interface class SyncAddonAction {}

abstract interface class AsyncAddonAction<T> {}

extension AddonActionExtension on Ref {
  /// Dispatches a [SyncAddonAction].
  void dispatch(SyncAddonAction action) {
    switch (action) {
      case NavigatePopAction a:
        redux(navigationReduxProvider).dispatch(a);
        break;
      case ShowSnackBarAction a:
        redux(snackBarReduxProvider).dispatch(a);
        break;
    }
  }

  /// Dispatches an [AsyncAddonAction].
  /// Returns the result of the action.
  Future<T?> dispatchAsync<T>(AsyncAddonAction<T> action) async {
    switch (action) {
      case NavigatePushAction<T> a:
        return await redux(navigationReduxProvider).dispatchAsyncTakeResult(a);
      case NavigatePushNamedAction<T> a:
        return await redux(navigationReduxProvider).dispatchAsyncTakeResult(a);
      default:
        throw ArgumentError('Unknown action: $action');
    }
  }
}
