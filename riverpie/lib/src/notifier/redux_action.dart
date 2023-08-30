// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/dispatcher.dart';
import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/observer/observer.dart';

/// The action that is dispatched by a [ReduxNotifier].
/// You should use [ReduxAction] or [AsyncReduxAction] instead.
sealed class BaseReduxAction<N extends BaseReduxNotifier<T>, T, R> {
  BaseReduxAction();

  /// Override this to have some logic before the action is dispatched.
  /// If this method throws, the [reduce] method will not be called but
  /// [after] will still be called.
  FutureOr<void> before() {}

  /// Override this to have some logic after the action is dispatched.
  /// This method is called even if [before] or [reduce] throws.
  void after() {}

  /// Access the notifier to access other notifiers.
  late N notifier;

  /// Returns the current state of the notifier.
  T get state => notifier.state;

  /// Dispatches a synchronous action and updates the state.
  /// Returns the new state.
  T dispatch(
    SynchronousReduxAction<BaseReduxNotifier<T>, T, dynamic> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatch(
      action,
      debugOrigin: debugOrigin ?? debugLabel,
      debugOriginRef: this,
    );
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state.
  Future<T> dispatchAsync(
    AsynchronousReduxAction<BaseReduxNotifier<T>, T, dynamic> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchAsync(
      action,
      debugOrigin: debugOrigin ?? debugLabel,
      debugOriginRef: this,
    );
  }

  /// Dispatches an action and updates the state.
  /// Returns the new state along with the result of the action.
  (T, R2) dispatchWithResult<R2>(
    ReduxActionWithResult<BaseReduxNotifier<T>, T, R2> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchWithResult<R2>(
      action,
      debugOrigin: debugOrigin ?? debugLabel,
      debugOriginRef: this,
    );
  }

  /// Dispatches an action and updates the state.
  /// Returns only the result of the action.
  R2 dispatchTakeResult<R2>(
    ReduxActionWithResult<BaseReduxNotifier<T>, T, R2> action, {
    String? debugOrigin,
  }) {
    return notifier
        .dispatchWithResult<R2>(
          action,
          debugOrigin: debugOrigin ?? debugLabel,
          debugOriginRef: this,
        )
        .$2;
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state along with the result of the action.
  Future<(T, R2)> dispatchAsyncWithResult<R2>(
    AsyncReduxActionWithResult<BaseReduxNotifier<T>, T, R2> action, {
    String? debugOrigin,
  }) async {
    return notifier.dispatchAsyncWithResult<R2>(
      action,
      debugOrigin: debugOrigin ?? debugLabel,
      debugOriginRef: this,
    );
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns only the result of the action.
  Future<R2> dispatchAsyncTakeResult<R2>(
    AsyncReduxActionWithResult<BaseReduxNotifier<T>, T, R2> action, {
    String? debugOrigin,
  }) async {
    final (_, result) = await notifier.dispatchAsyncWithResult<R2>(
      action,
      debugOrigin: debugOrigin ?? debugLabel,
      debugOriginRef: this,
    );
    return result;
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
      debugOriginRef: this,
    );
  }

  /// Emits a message to the observer.
  void emitMessage(String message) {
    _observer?.handleEvent(
      MessageEvent(message, this),
    );
  }

  /// The debug label of the action.
  /// Override this getter to provide a custom label.
  String get debugLabel => '$runtimeType';

  RiverpieObserver? _observer;

  @internal
  void internalSetup(N notifier, RiverpieObserver? observer) {
    this.notifier = notifier;
    _observer = observer;
  }

  @internal
  FutureOr<(T, R)> internalWrapReduce();
}

abstract class SynchronousReduxAction<N extends BaseReduxNotifier<T>, T, R>
    extends BaseReduxAction<N, T, R> {
  SynchronousReduxAction();

  /// See [BaseReduxAction.before] for documentation.
  @override
  void before() {}

  @internal
  @override
  (T, R) internalWrapReduce();
}

abstract class AsynchronousReduxAction<N extends BaseReduxNotifier<T>, T, R>
    extends BaseReduxAction<N, T, R> {
  AsynchronousReduxAction();

  /// See [BaseReduxAction.before] for documentation.
  @override
  Future<void> before() async {}

  @internal
  @override
  Future<(T, R)> internalWrapReduce();
}

/// The action that is dispatched by a [ReduxNotifier].
/// Trigger this with [dispatch].
abstract class ReduxAction<N extends BaseReduxNotifier<T>, T>
    extends SynchronousReduxAction<N, T, void> {
  ReduxAction();

  /// The method that returns the new state.
  T reduce();

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
  T wrapReduce() => reduce();

  @override
  @internal
  @nonVirtual
  (T, void) internalWrapReduce() {
    return (wrapReduce(), null);
  }
}

/// The asynchronous action that is dispatched by a [ReduxNotifier].
/// Trigger this with [dispatchAsync].
abstract class AsyncReduxAction<N extends BaseReduxNotifier<T>, T>
    extends AsynchronousReduxAction<N, T, void> {
  /// The method that returns the new state.
  Future<T> reduce();

  /// Override this to have some logic before and after the [reduce] method.
  /// Specifically, this method is called after [before] and before [after]:
  /// [before] -> [wrapReduce] -> [after]
  ///
  /// Usage:
  /// Future<int> wrapReduce() async {
  ///   someLogicBeforeReduce();
  ///   final result = await reduce();
  ///   someLogicAfterReduce();
  ///   return result;
  /// }
  Future<T> wrapReduce() => reduce();

  @override
  @internal
  @nonVirtual
  Future<(T, void)> internalWrapReduce() async {
    return (await wrapReduce(), null);
  }
}

abstract class ReduxActionWithResult<N extends BaseReduxNotifier<T>, T, R>
    extends SynchronousReduxAction<N, T, R> {
  /// The method that returns the new state.
  (T, R) reduce();

  /// Override this to have some logic before and after the [reduce] method.
  /// Specifically, this method is called after [before] and before [after]:
  /// [before] -> [wrapReduce] -> [after]
  (T, R) wrapReduce() => reduce();

  @override
  @internal
  @nonVirtual
  (T, R) internalWrapReduce() {
    return wrapReduce();
  }
}

abstract class AsyncReduxActionWithResult<N extends BaseReduxNotifier<T>, T, R>
    extends AsynchronousReduxAction<N, T, R> {
  /// The method that returns the new state.
  Future<(T, R)> reduce();

  /// Override this to have some logic before and after the [reduce] method.
  /// Specifically, this method is called after [before] and before [after]:
  /// [before] -> [wrapReduce] -> [after]
  Future<(T, R)> wrapReduce() => reduce();

  @override
  @internal
  @nonVirtual
  Future<(T, R)> internalWrapReduce() {
    return wrapReduce();
  }
}
