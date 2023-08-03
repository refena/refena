import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
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

  final _listeners = <State>{};
  int _listenerAddCount = 0;

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
      notifyListeners();
    }
  }

  @protected
  bool updateShouldNotify(T prev, T next) {
    return !identical(prev, next);
  }

  @protected
  void notifyListeners() {
    _removeUnusedListeners();

    for (final listener in _listeners) {
      // ignore: invalid_use_of_protected_member
      listener.setState(() {});
    }
  }

  @internal
  void setRefAndInit(Ref ref) {
    _ref = ref;
    _state = init();
    _initialized = true;
  }

  @internal
  void addListener(State state) {
    _listenerAddCount++;
    if (_listenerAddCount == 10) {
      // We already clear listeners on each notify.
      // This handling is for scenarios when the state never changes.
      _listenerAddCount = 0;
      _removeUnusedListeners();
    }

    _listeners.add(state);
  }

  void _removeUnusedListeners() {
    // remove any listener that has been disposed
    _listeners.removeWhere((state) => !state.mounted);
  }
}
