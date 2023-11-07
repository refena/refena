// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:refena/src/action/dispatcher.dart';
import 'package:refena/src/action/global_action_dispatcher.dart';
import 'package:refena/src/container.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/notifier/rebuildable.dart';
import 'package:refena/src/notifier/types/redux_notifier.dart';
import 'package:refena/src/observer/event.dart';
import 'package:refena/src/observer/observer.dart';
import 'package:refena/src/provider/types/redux_provider.dart';
import 'package:refena/src/provider/types/view_provider.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';
import 'package:refena/src/reference.dart';
import 'package:refena/src/util/batched_stream_controller.dart';

part 'global_action.dart';

part 'watch_action.dart';

/// The action that is dispatched by a [ReduxNotifier].
/// You should use [ReduxAction] or [AsyncReduxAction] instead.
abstract class BaseReduxAction<N extends BaseReduxNotifier<T>, T, R>
    with IdReference
    implements LabeledReference {
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
  /// It does not use the exact N type because then Dart cannot infer T2 type.
  /// This is okay because the developer
  /// won't access N inside the dispatcher anyway.
  ///
  /// Usage:
  /// class MyNotifier extends ReduxNotifier<int> {
  ///   final ServiceB serviceB;
  /// }
  /// // ...
  /// external(notifier.serviceB).dispatch(SubtractAction(11));
  Dispatcher<BaseReduxNotifier<T2>, T2> external<T2>(
    BaseReduxNotifier<T2> notifier,
  ) {
    return Dispatcher<BaseReduxNotifier<T2>, T2>(
      notifier: notifier,
      debugOrigin: debugLabel,
      debugOriginRef: this,
    );
  }

  /// Emits a message to the observer.
  void emitMessage(String message) {
    _observer?.dispatchEvent(
      MessageEvent(message, this),
    );
  }

  /// Whether the [ActionDispatchedEvent] should have the
  /// [ActionDispatchedEvent.debugOriginRef] of the origin of the action.
  /// This is true by default for better visualization in the tracing page.
  ///
  /// Turn this off if this action is dispatched by a long running action
  /// where the origin action puts this action too far in the past.
  ///
  /// The [ActionDispatchedEvent.debugOrigin] is unaffected by this.
  bool get trackOrigin => true;

  /// The debug label of the action.
  /// Override this getter to provide a custom label.
  @override
  String get debugLabel => '$runtimeType';

  RefenaObserver? _observer;

  /// Provides access to [Ref].
  /// This getter is used to allow dispatching global actions.
  /// This might be null in unit tests, when used without [RefenaContainer].
  Ref? _originalRef;

  late final _ref = ProxyRef(
    _originalRef!.container,
    debugLabel,
    this,
  );

  late N _notifier;

  Type get notifierType => N;

  @internal
  FutureOr<(T, R)> internalWrapReduce();
}

@internal
extension InternalBaseReduxActionExt<N extends BaseReduxNotifier<T>, T, R>
    on BaseReduxAction<N, T, R> {
  void internalSetup(Ref? ref, N notifier, RefenaObserver? observer) {
    _originalRef = ref;
    _notifier = notifier;
    _observer = observer;
  }
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
///
/// {@category Redux}
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
///
/// {@category Redux}
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
///
/// {@category Redux}
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
///
/// {@category Redux}
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
