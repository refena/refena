import 'dart:async';

import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/dispatcher.dart';

/// A [ReduxAction] is dispatched by a [ReduxNotifier].
abstract class ReduxAction<N extends BaseReduxNotifier, T> {
  ReduxAction();

  /// This method called by the notifier when an action is dispatched.
  FutureOr<T> reduce();

  /// Override this to have some logic before the action is dispatched.
  /// If this method throws, the [reduce] method will not be called but
  /// [after] will still be called.
  FutureOr<void> before() {}

  /// Override this to have some logic after the action is dispatched.
  /// This method is called even if [before] or [reduce] throws.
  void after() {}

  /// Override this to have some logic before and after the [reduce] method.
  /// Specifically, this method is called after [before] and before [after]:
  /// [before] -> [wrapReduce] -> [after]
  ///
  /// Usage:
  /// int wrapReduce() {
  ///   someLogicBeforeReduce();
  ///   final result = reduce();
  ///   someLogicAfterReduce();
  ///   return result;
  /// }
  FutureOr<T> wrapReduce() => reduce();

  /// Access the notifier to access other notifiers.
  late N notifier;

  /// Returns the current state of the notifier.
  T get state => notifier.state;

  /// Dispatches a new action.
  FutureOr<void> dispatch(ReduxAction<N, T> action) {
    // ignore: invalid_use_of_protected_member
    return notifier.dispatch(action, debugOrigin: debugLabel);
  }

  /// Use this method to dispatch external actions within an action.
  /// This ensures that the dispatched action has the correct [debugOrigin].
  ///
  /// Usage:
  /// class MyNotifier extends ReduxNotifier<int> {
  ///   final ServiceB serviceB;
  /// }
  /// // ...
  /// external(notifier.serviceB).dispatch(SubtractAction(11));
  Dispatcher<N2, T2> external<N2 extends BaseReduxNotifier<T2>, T2>(
    N2 notifier,
  ) {
    return Dispatcher<N2, T2>(
      notifier: notifier,
      debugOrigin: debugLabel,
    );
  }

  /// The debug label of the action.
  /// Override this getter to provide a custom label.
  @protected
  String get debugLabel => '$runtimeType';

  @internal
  void internalSetup(N notifier) {
    this.notifier = notifier;
  }
}
