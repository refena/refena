// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:riverpie/src/action/dispatcher.dart';
import 'package:riverpie/src/action/global_action_dispatcher.dart';
import 'package:riverpie/src/labeled_reference.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/types/redux_notifier.dart';
import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/types/redux_provider.dart';
import 'package:riverpie/src/proxy_ref.dart';
import 'package:riverpie/src/ref.dart';

part 'global_action.dart';

/// The action that is dispatched by a [ReduxNotifier].
/// You should use [ReduxAction] or [AsyncReduxAction] instead.
abstract class BaseReduxAction<N extends BaseReduxNotifier<T>, T, R>
    with LabeledReference {
  BaseReduxAction();

  /// Override this to have some logic before the action is dispatched.
  /// If this method throws, the [reduce] method will not be called but
  /// [after] will still be called.
  FutureOr<void> before() {}

  /// Override this to have some logic after the action is dispatched.
  /// This method is called even if [before] or [reduce] throws.
  void after() {}

  /// Access the notifier to access other notifiers.
  N get notifier => _notifier;

  /// Returns the current state of the notifier.
  T get state => _notifier.state;

  /// Dispatches a synchronous action and updates the state.
  /// Returns the new state.
  T dispatch(
    SynchronousReduxAction<N, T, dynamic> action, {
    String? debugOrigin,
  }) {
    return _notifier.dispatch(
      action,
      debugOrigin: debugOrigin ?? debugLabel,
      debugOriginRef: this,
    );
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state.
  Future<T> dispatchAsync(
    AsynchronousReduxAction<N, T, dynamic> action, {
    String? debugOrigin,
  }) {
    return _notifier.dispatchAsync(
      action,
      debugOrigin: debugOrigin ?? debugLabel,
      debugOriginRef: this,
    );
  }

  /// Dispatches an action and updates the state.
  /// Returns the new state along with the result of the action.
  (T, R2) dispatchWithResult<R2>(
    BaseReduxActionWithResult<N, T, R2> action, {
    String? debugOrigin,
  }) {
    return _notifier.dispatchWithResult<R2>(
      action,
      debugOrigin: debugOrigin ?? debugLabel,
      debugOriginRef: this,
    );
  }

  /// Dispatches an action and updates the state.
  /// Returns only the result of the action.
  R2 dispatchTakeResult<R2>(
    BaseReduxActionWithResult<N, T, R2> action, {
    String? debugOrigin,
  }) {
    return _notifier.dispatchTakeResult<R2>(
      action,
      debugOrigin: debugOrigin ?? debugLabel,
      debugOriginRef: this,
    );
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state along with the result of the action.
  Future<(T, R2)> dispatchAsyncWithResult<R2>(
    BaseAsyncReduxActionWithResult<N, T, R2> action, {
    String? debugOrigin,
  }) async {
    return _notifier.dispatchAsyncWithResult<R2>(
      action,
      debugOrigin: debugOrigin ?? debugLabel,
      debugOriginRef: this,
    );
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns only the result of the action.
  Future<R2> dispatchAsyncTakeResult<R2>(
    BaseAsyncReduxActionWithResult<N, T, R2> action, {
    String? debugOrigin,
  }) {
    return _notifier.dispatchAsyncTakeResult<R2>(
      action,
      debugOrigin: debugOrigin ?? debugLabel,
      debugOriginRef: this,
    );
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
  @override
  String get debugLabel => '$runtimeType';

  RiverpieObserver? _observer;

  /// Provides access to [Ref].
  /// This getter is used to allow dispatching global actions.
  /// This might be null in unit tests, when used without [RiverpieContainer].
  Ref? _originalRef;

  late final _ref = ProxyRef(
    _originalRef!,
    debugLabel,
    this,
  );

  late N _notifier;

  Type get notifierType => N;

  @internal
  void internalSetup(Ref? ref, N notifier, RiverpieObserver? observer) {
    _originalRef = ref;
    _notifier = notifier;
    _observer = observer;
  }

  @internal
  FutureOr<(T, R)> internalWrapReduce();
}

@internal
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

@internal
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

/// A helper class in the hierarchy to allow
/// [ReduxActionWithResult] and [GlobalActionWithResult].
@internal
abstract class BaseReduxActionWithResult<N extends BaseReduxNotifier<T>, T, R>
    extends SynchronousReduxAction<N, T, R> {}

/// The action that is dispatched by a [ReduxNotifier].
///
/// This action allows returning an additional result of type [R] that
/// won't be stored in the state.
///
/// Trigger this with [dispatch], [dispatchWithResult] or [dispatchTakeResult].
abstract class ReduxActionWithResult<N extends BaseReduxNotifier<T>, T, R>
    extends BaseReduxActionWithResult<N, T, R> {
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

/// A helper class in the hierarchy to allow
/// [AsyncReduxActionWithResult] and [AsyncGlobalActionWithResult].
@internal
abstract class BaseAsyncReduxActionWithResult<N extends BaseReduxNotifier<T>, T,
    R> extends AsynchronousReduxAction<N, T, R> {}

/// The asynchronous action that is dispatched by a [ReduxNotifier].
///
/// This action allows returning an additional result of type [R] that
/// won't be stored in the state.
///
/// Trigger this with [dispatchAsync], [dispatchAsyncWithResult] or
/// [dispatchAsyncTakeResult].
abstract class AsyncReduxActionWithResult<N extends BaseReduxNotifier<T>, T, R>
    extends BaseAsyncReduxActionWithResult<N, T, R> {
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
