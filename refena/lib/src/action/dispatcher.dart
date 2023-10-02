// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:refena/src/action/redux_action.dart';
import 'package:refena/src/labeled_reference.dart';
import 'package:refena/src/notifier/base_notifier.dart';

/// A proxy class to provide a custom [debugOrigin] for [dispatch].
///
/// Usage:
/// ref.redux(myReduxProvider).dispatch(SubtractAction(2));
class Dispatcher<N extends BaseReduxNotifier<T>, T> {
  Dispatcher({
    required this.notifier,
    required this.debugOrigin,
    required this.debugOriginRef,
  });

  /// The notifier to dispatch actions to.
  final N notifier;

  /// The origin of the dispatched action.
  /// Used for debugging purposes.
  /// Usually, the class name of the widget, provider or notifier.
  final String debugOrigin;

  /// The origin reference of the dispatched action.
  final LabeledReference debugOriginRef;

  /// Dispatches an [action] to the [notifier].
  /// Returns the new state.
  T dispatch(
    SynchronousReduxAction<N, T, dynamic> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatch(
      action,
      debugOrigin: debugOrigin ?? this.debugOrigin,
      debugOriginRef: debugOriginRef,
    );
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state.
  Future<T> dispatchAsync(
    AsynchronousReduxAction<N, T, dynamic> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchAsync(
      action,
      debugOrigin: debugOrigin ?? this.debugOrigin,
      debugOriginRef: debugOriginRef,
    );
  }

  /// Dispatches an action and updates the state.
  /// Returns the new state along with the result of the action.
  (T, R2) dispatchWithResult<R2>(
    BaseReduxActionWithResult<N, T, R2> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchWithResult<R2>(
      action,
      debugOrigin: debugOrigin ?? this.debugOrigin,
      debugOriginRef: debugOriginRef,
    );
  }

  /// Dispatches an action and updates the state.
  /// Returns only the result of the action.
  R2 dispatchTakeResult<R2>(
    BaseReduxActionWithResult<N, T, R2> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchTakeResult<R2>(
      action,
      debugOrigin: debugOrigin ?? this.debugOrigin,
      debugOriginRef: debugOriginRef,
    );
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state along with the result of the action.
  Future<(T, R2)> dispatchAsyncWithResult<R2>(
    BaseAsyncReduxActionWithResult<N, T, R2> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchAsyncWithResult<R2>(
      action,
      debugOrigin: debugOrigin ?? this.debugOrigin,
      debugOriginRef: debugOriginRef,
    );
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns only the result of the action.
  Future<R2> dispatchAsyncTakeResult<R2>(
    BaseAsyncReduxActionWithResult<N, T, R2> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchAsyncTakeResult<R2>(
      action,
      debugOrigin: debugOrigin ?? this.debugOrigin,
      debugOriginRef: debugOriginRef,
    );
  }
}
