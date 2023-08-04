import 'package:flutter/material.dart';

typedef ListenerCallback<T> = void Function(T prev, T next);

class ListenerConfig<T> {
  final ListenerCallback<T>? callback;

  ListenerConfig({
    required this.callback,
  });
}

class NotifierListeners<T> {
  final _listeners = <State, ListenerConfig<T>>{};
  int _listenerAddCount = 0;

  void notify(T prev, T next) {
    _removeUnusedListeners();

    _listeners.forEach((state, config) {
      if (config.callback != null) {
        config.callback!.call(prev, next);
      }

      // ignore: invalid_use_of_protected_member
      state.setState(() {});
    });
  }

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

  void _removeUnusedListeners() {
    // remove any listener that has been disposed
    _listeners.removeWhere((state, config) => !state.mounted);
  }
}
