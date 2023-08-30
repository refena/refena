import 'package:riverpie/riverpie.dart';
import 'package:riverpie_flutter/src/addons/snack_bar.dart';

/// A flag to allow the usage of
/// the [Ref.dispatch] convenience method.
abstract interface class AddonAction {}

extension AddonActionExtension on Ref {
  /// Dispatches an [AddonAction].
  void dispatch(AddonAction action) {
    switch (action) {
      case ShowSnackBarAction a:
        redux(snackBarReduxProvider).dispatch(a);
        break;
    }
  }
}
