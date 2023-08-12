import 'dart:async';

import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/listener.dart';
import 'package:riverpie/src/notifier/rebuildable.dart';
import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/ref.dart';

abstract class BaseNotifier<T> {
  bool _initialized = false;
  RiverpieObserver? _observer;

  final String? debugLabel;

  /// The current state of the notifier.
  /// It will be initialized by [init].
  late T _state;

  /// A collection of listeners
  late final NotifierListeners<T> _listeners;

  BaseNotifier({required this.debugLabel});

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
      final notified = _listeners.notifyAll(oldState, _state);
      _observer?.handleEvent(
        NotifyEvent<T>(
          notifier: this,
          prev: oldState,
          next: value,
          flagRebuild: notified!,
        ),
      );
    }
  }

  /// Override this if you want to a different kind of equality.
  @protected
  bool updateShouldNotify(T prev, T next) {
    return !identical(prev, next);
  }

  @internal
  void preInit(Ref ref, RiverpieObserver? observer);

  @internal
  void addListener(Rebuildable rebuildable, ListenerConfig<T> config) {
    _listeners.addListener(rebuildable, config);
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

  Notifier({String? debugLabel}) : super(debugLabel: debugLabel);

  @internal
  @override
  void preInit(Ref ref, RiverpieObserver? observer) {
    _ref = ref;
    _observer = observer;
    _listeners = NotifierListeners(this, observer);
    _state = init();
    _initialized = true;
  }
}

/// A [Notifier] but without [ref] making this notifier self-contained.
///
/// Can be used in combination with dependency injection,
/// where you provide the dependencies via constructor.
abstract class PureNotifier<T> extends BaseNotifier<T> {
  PureNotifier({String? debugLabel}) : super(debugLabel: debugLabel);

  @internal
  @override
  void preInit(Ref ref, RiverpieObserver? observer) {
    _observer = observer;
    _listeners = NotifierListeners<T>(this, observer);
    _state = init();
    _initialized = true;
  }
}
