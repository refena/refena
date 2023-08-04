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
  void addListener(State state, ListenerCallback<T>? callback) {
    _listeners.addListener(state, ListenerConfig<T>(callback: callback));
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
