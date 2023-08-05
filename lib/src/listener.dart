import 'dart:async';

import 'package:flutter/material.dart';

typedef ListenerCallback<T> = void Function(T prev, T next);

/// Each [State] is associated with exactly one [ListenerConfig] object.
class ListenerConfig<T> {
  /// The callback to call when the state changes.
  final ListenerCallback<T>? callback;

  /// Should only update if this returns true.
  final bool Function(T prev, T next)? selector;

  ListenerConfig({
    required this.callback,
    required this.selector,
  });
}

/// The object that gets fired by the stream.
class NotifierEvent<T> {
  final T prev;
  final T next;

  NotifierEvent(this.prev, this.next);

  @override
  String toString() {
    return 'NotifierEvent($prev -> $next)';
  }
}

class NotifierListeners<T> {
  final _listeners = <State, ListenerConfig<T>>{};
  int _listenerAddCount = 0;

  final _stream = StreamController<NotifierEvent<T>>.broadcast();

  void notifyAll(T prev, T next) {
    _removeUnusedListeners();

    _listeners.forEach((state, config) {
      if (config.selector != null && !config.selector!(prev, next)) {
        return;
      }

      if (config.callback != null) {
        config.callback!.call(prev, next);
      }

      // ignore: invalid_use_of_protected_member
      state.setState(() {});
    });

    _stream.add(NotifierEvent(prev, next));
  }

  /// Adds a listener to the notifier.
  /// The listener is automatically removed when the state is disposed.
  void addListener(State state, ListenerConfig<T> config) {
    if (!_listeners.containsKey(state)) {
      _listenerAddCount++;
      if (_listenerAddCount == 10) {
        // We already clear listeners on each notify.
        // This handling is for scenarios when the state never changes.
        _listenerAddCount = 0;
        _removeUnusedListeners();
      }

      _listeners[state] = config;
    }
  }

  /// Listen manually to the notifier.
  Stream<NotifierEvent<T>> getStream() {
    return _stream.stream;
  }

  void _removeUnusedListeners() {
    // remove any listener that has been disposed
    _listeners.removeWhere((state, config) => !state.mounted);
  }
}
