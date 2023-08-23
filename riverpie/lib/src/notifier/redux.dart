import 'dart:async';

import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';

/// A [ReduxAction] are dispatched by a [ReduxNotifier].
abstract class ReduxAction<N extends BaseReduxNotifier, T> {
  ReduxAction();

  /// This method called by the notifier when an action is dispatched.
  FutureOr<T> reduce();

  /// Access the notifier to access other notifiers.
  late N notifier;

  /// Returns the current state of the notifier.
  T get state => notifier.state;

  /// Dispatches a new action.
  void dispatch(ReduxAction<N, T> action) {
    notifier.dispatch(action, debugOrigin: debugLabel);
  }

  /// The debug label of the action.
  /// Override this getter to provide a custom label.
  @protected
  String get debugLabel => '$runtimeType';

  @internal
  void setup(N notifier) {
    this.notifier = notifier;
  }
}
