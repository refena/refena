import 'dart:async';

import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/notifier_event.dart';
import 'package:riverpie/src/notifier/rebuildable.dart';
import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/observer/observer.dart';

typedef ListenerCallback<T> = void Function(T prev, T next);

/// Each [State] is associated with exactly one [ListenerConfig] object.
class ListenerConfig<T> {
  /// The callback to call when the state changes.
  final ListenerCallback<T>? callback;

  /// Should only update if this returns true.
  final bool Function(T prev, T next)? rebuildWhen;

  ListenerConfig({
    required this.callback,
    required this.rebuildWhen,
  });
}

class NotifierListeners<T> {
  final RiverpieObserver? _observer;
  final BaseNotifier<T> _notifier;
  final _listeners = <Rebuildable, ListenerConfig<T>>{};
  int _listenerAddCount = 0;

  final _stream = StreamController<NotifierEvent<T>>.broadcast();

  NotifierListeners(this._notifier, this._observer);

  void notifyAll({
    required T prev,
    required T next,
    ChangeEvent? changeEvent,
    RebuildEvent? rebuildEvent,
  }) {
    _removeUnusedListeners();

    _listeners.forEach((rebuildable, config) {
      if (config.rebuildWhen != null && !config.rebuildWhen!(prev, next)) {
        return;
      }

      if (config.callback != null) {
        config.callback!.call(prev, next);
      }

      // notify rebuildable (ref.watch)
      rebuildable.rebuild(changeEvent, rebuildEvent);

      changeEvent?.rebuild.add(rebuildable);
      rebuildEvent?.rebuild.add(rebuildable);
    });

    // notify manual listeners (ref.stream)
    _stream.add(NotifierEvent(prev, next));
  }

  /// Adds a listener to the notifier.
  /// The listener is automatically removed when the state is disposed.
  void addListener(Rebuildable rebuildable, ListenerConfig<T> config) {
    if (!_listeners.containsKey(rebuildable)) {
      _listenerAddCount++;
      if (_listenerAddCount == 10) {
        // We already clear listeners on each notify.
        // This handling is for scenarios when the state never changes.
        _listenerAddCount = 0;
        _removeUnusedListeners();
      }

      _observer?.handleEvent(
        ListenerAddedEvent(notifier: _notifier, rebuildable: rebuildable),
      );
    }

    // We still need to add the listener even if it is already added.
    // This is because the config may have changed.
    _listeners[rebuildable] = config;
  }

  /// Listen manually to the notifier.
  Stream<NotifierEvent<T>> getStream() {
    return _stream.stream;
  }

  void dispose() {
    _listeners.clear();
    _stream.close();
  }

  void _removeUnusedListeners() {
    // remove any listener that has been disposed
    final observer = _observer;
    if (observer != null) {
      final removed = <Rebuildable>[];
      _listeners.removeWhere((rebuildable, config) {
        if (rebuildable.disposed) {
          removed.add(rebuildable);
          return true;
        }
        return false;
      });
      for (final r in removed) {
        observer.handleEvent(
          ListenerRemovedEvent(notifier: _notifier, rebuildable: r),
        );
      }
    } else {
      _listeners.removeWhere((rebuildable, config) => rebuildable.disposed);
    }
  }
}
