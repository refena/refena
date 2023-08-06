import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/src/listener.dart';
import 'package:riverpie/src/ref.dart';

abstract class BaseNotifier<T> {
  bool _initialized = false;

  late T _state;

  /// A collection of listeners
  final _listeners = NotifierListeners<T>();

  /// Initializes the state of the notifier.
  /// This method is called only once and
  /// as soon as the notifier is accessed the first time.
  T init();

  /// Gets the current state.
  @protected
  T get state => _state;

  /// Sets the state and notify listeners
  @protected
  set state(T value) {
    if (!_initialized) {
      // We allow initializing the state before the initialization
      // by Riverpie is done.
      // The only drawback is that ref is not available during this phase.
      // Special providers like [FutureProvider] use this.
      _state = value;
      return;
    }

    final oldState = _state;
    _state = value;

    if (_initialized && updateShouldNotify(oldState, _state)) {
      _listeners.notifyAll(oldState, _state);
    }
  }

  /// Override this if you want to a different kind of equality.
  @protected
  bool updateShouldNotify(T prev, T next) {
    return !identical(prev, next);
  }

  @internal
  void preInit(Ref ref);

  @internal
  void addListener(State state, ListenerConfig<T> config) {
    _listeners.addListener(state, config);
  }

  @internal
  Stream<NotifierEvent<T>> getStream() {
    return _listeners.getStream();
  }
}

/// A notifier holds a state and notifies its listeners when the state changes.
/// The listeners are added automatically when calling [ref.watch].
///
/// Be aware that notifiers are never disposed.
/// If you hold a lot of data in the state,
/// you should consider implement a "reset" logic.
///
/// This [Notifier] has access to [ref] for fast development.
abstract class Notifier<T> extends BaseNotifier<T> {
  late Ref _ref;

  @protected
  Ref get ref => _ref;

  @internal
  @override
  void preInit(Ref ref) {
    _ref = ref;
    _state = init();
    _initialized = true;
  }
}

/// A [Notifier] but without [ref] making this notifier self-contained.
///
/// Can be used in combination with dependency injection,
/// where you provide the dependencies via constructor.
abstract class PureNotifier<T> extends BaseNotifier<T> {
  @internal
  @override
  void preInit(Ref ref) {
    _state = init();
    _initialized = true;
  }
}

/// A pre-implemented notifier for simple use cases.
/// You may add a [listener] to retrieve every [setState] event.
///
/// Usage:
/// final counterProvider = NotifierProvider<StateNotifier<int>, int>((ref) {
///   return StateNotifier(42);
/// });
///
/// ref.notifier(counterProvider).setState(456);
class StateNotifier<T> extends PureNotifier<T> {
  final ListenerCallback<T>? _listener;

  StateNotifier(T initial, {ListenerCallback<T>? listener}) : _listener = listener {
    state = initial;
  }

  @override
  T init() => state;

  /// Use this to change the state of the notifier.
  ///
  /// Usage:
  /// ref.notifier(myProvider).setState('new value');
  void setState(T newState) {
    final oldState = state;
    state = newState;
    if (_listener != null) {
      _listener!.call(oldState, newState);
    }
  }
}