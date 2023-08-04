import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/src/listener.dart';
import 'package:riverpie/src/ref.dart';

/// A notifier holds a state and notifies its listeners when the state changes.
/// The listeners are added automatically when calling [ref.watch].
///
/// Be aware that notifiers are never disposed.
/// If you hold a lot of data in the state,
/// you should consider implement a "reset" logic.
abstract class Notifier<T> {
  bool _initialized = false;
  late Ref _ref;
  late T _state;

  final _listeners = NotifierListeners<T>();

  /// Initializes the state of the notifier.
  /// This method is called only once and
  /// as soon as the notifier is accessed the first time.
  T init();

  @protected
  Ref get ref => _ref;

  @protected
  T get state => _state;

  @protected
  set state(T value) {
    final oldState = _state;
    _state = value;

    if (_initialized && updateShouldNotify(oldState, _state)) {
      _listeners.notify(oldState, _state);
    }
  }

  @protected
  bool updateShouldNotify(T prev, T next) {
    return !identical(prev, next);
  }

  @internal
  void setRefAndInit(Ref ref) {
    _ref = ref;
    _state = init();
    _initialized = true;
  }

  @internal
  void addListener(State state, ListenerCallback<T>? callback) {
    _listeners.addListener(state, ListenerConfig<T>(callback: callback));
  }
}
