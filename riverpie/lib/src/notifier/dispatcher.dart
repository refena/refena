import 'dart:async';

import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/redux.dart';

/// A proxy class to provide a custom [debugOrigin] for [dispatch].
///
/// Usage:
/// ref.redux(myReduxProvider).dispatch(SubtractAction(2));
class Dispatcher<N extends BaseReduxNotifier<T>, T> {
  Dispatcher({
    required this.notifier,
    required this.debugOrigin,
  });

  /// The notifier to dispatch actions to.
  final N notifier;

  /// The origin of the dispatched action.
  /// Used for debugging purposes.
  /// Usually, the class name of the widget, provider or notifier.
  final String debugOrigin;

  /// Dispatches an [action] to the [notifier].
  FutureOr<void> dispatch(ReduxAction<N, T> action, {String? debugOrigin}) {
    // ignore: invalid_use_of_protected_member
    return notifier.dispatch(
      action,
      debugOrigin: debugOrigin ?? this.debugOrigin,
    );
  }
}
