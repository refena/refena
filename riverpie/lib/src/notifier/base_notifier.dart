import 'dart:async';

import 'package:meta/meta.dart';
import 'package:riverpie/src/async_value.dart';
import 'package:riverpie/src/container.dart';
import 'package:riverpie/src/notifier/listener.dart';
import 'package:riverpie/src/notifier/notifier_event.dart';
import 'package:riverpie/src/notifier/rebuildable.dart';
import 'package:riverpie/src/notifier/redux_action.dart';
import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/types/redux_provider.dart';
import 'package:riverpie/src/ref.dart';

@internal
abstract class BaseNotifier<T> {
  bool _initialized = false;
  RiverpieObserver? _observer;

  final String? debugLabel;

  /// The current state of the notifier.
  /// It will be initialized by [init].
  late T _state;

  /// A collection of listeners
  late final NotifierListeners<T> _listeners;

  BaseNotifier({this.debugLabel});

  /// Gets the current state.
  @nonVirtual
  T get state => _state;

  /// Sets the state and notify listeners
  @protected
  set state(T value) {
    _setState(value, null);
  }

  /// Sets the state and notify listeners (the actual implementation).
  // We need to extract this method to make [ReduxNotifier] work.
  void _setState(T value, Object? action) {
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
        ChangeEvent<T>(
          notifier: this,
          action: action,
          prev: oldState,
          next: value,
          rebuild: notified!,
        ),
      );
    }
  }

  /// Override this if you want to a different kind of equality.
  @protected
  bool updateShouldNotify(T prev, T next) {
    return !identical(prev, next);
  }

  /// Handles the actual initialization of the notifier.
  /// Calls [init] internally.
  @internal
  void internalSetup(RiverpieContainer container, RiverpieObserver? observer);

  @internal
  void addListener(Rebuildable rebuildable, ListenerConfig<T> config) {
    _listeners.addListener(rebuildable, config);
  }

  @internal
  Stream<NotifierEvent<T>> getStream() {
    return _listeners.getStream();
  }

  @override
  String toString() {
    return '$runtimeType(state: ${_initialized ? _state : 'uninitialized'})';
  }
}

@internal
abstract class BaseSyncNotifier<T> extends BaseNotifier<T> {
  BaseSyncNotifier({super.debugLabel});

  /// Initializes the state of the notifier.
  /// This method is called only once and
  /// as soon as the notifier is accessed the first time.
  T init();

  @override
  @internal
  @mustCallSuper
  void internalSetup(RiverpieContainer container, RiverpieObserver? observer) {
    _listeners = NotifierListeners<T>(this, observer);
    _observer = observer;
    _state = init();
    _initialized = true;
  }
}

@internal
abstract class BaseAsyncNotifier<T> extends BaseNotifier<AsyncValue<T>> {
  late Future<T> _future;
  int _futureCount = 0;

  BaseAsyncNotifier({super.debugLabel});

  @protected
  Future<T> get future => _future;

  @protected
  set future(Future<T> value) {
    _setFutureAndListen(value);
  }

  void _setFutureAndListen(Future<T> value) async {
    _future = value;
    _futureCount++;
    state = AsyncValue<T>.loading();
    final currentCount = _futureCount; // after the setter, as it may change
    try {
      final value = await _future;
      if (currentCount != _futureCount) {
        // The future has been changed in the meantime.
        return;
      }
      state = AsyncValue.withData(value);
    } catch (error, stackTrace) {
      if (currentCount != _futureCount) {
        // The future has been changed in the meantime.
        return;
      }
      state = AsyncValue<T>.withError(error, stackTrace);
    }
  }

  @override
  @protected
  set state(AsyncValue<T> value) {
    _futureCount++; // invalidate previous future callbacks
    super.state = value;
  }

  /// Initializes the state of the notifier.
  /// This method is called only once and
  /// as soon as the notifier is accessed the first time.
  Future<T> init();

  @override
  @internal
  @mustCallSuper
  void internalSetup(RiverpieContainer container, RiverpieObserver? observer) {
    _listeners = NotifierListeners<AsyncValue<T>>(this, observer);
    _observer = observer;

    // do not set future directly, as the setter may be overridden
    _setFutureAndListen(init());

    _initialized = true;
  }
}

/// A notifier where the state can be updated by dispatching actions
/// by calling [dispatch].
///
/// You do not have access to [Ref] in this notifier, so you need to pass
/// the required dependencies via constructor.
///
/// From outside, you can should dispatch actions with
/// `ref.redux(provider).dispatch(action)`.
///
/// Dispatching from the notifier itself is also possible but
/// you will lose the implicit [debugOrigin] stored in a [Ref].
@internal
abstract class BaseReduxNotifier<T> extends BaseNotifier<T> {
  BaseReduxNotifier({super.debugLabel}) {
    // Initialize right away for easier unit testing.
    _state = init();
  }

  /// A map of overrides for the reducers.
  Map<Type, MockReducer<T>?>? _overrides;

  /// Dispatches an action and updates the state.
  /// Returns the new state.
  @protected
  @nonVirtual
  T dispatch(
    ReduxAction<BaseReduxNotifier<T>, T> action, {
    String? debugOrigin,
  }) {
    return _dispatchWithResult<void>(action, debugOrigin: debugOrigin).$1;
  }

  /// Dispatches an action and updates the state.
  /// Returns the new state along with the result of the action.
  @protected
  @nonVirtual
  (T, R) dispatchWithResult<R>(
    ReduxActionWithResult<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
  }) {
    return _dispatchWithResult<R>(action, debugOrigin: debugOrigin);
  }

  /// Dispatches an action and updates the state.
  /// Returns only the result of the action.
  @protected
  @nonVirtual
  R dispatchTakeResult<R>(
    ReduxActionWithResult<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
  }) {
    return _dispatchWithResult<R>(action, debugOrigin: debugOrigin).$2;
  }

  @nonVirtual
  (T, R) _dispatchWithResult<R>(
    SynchronousReduxAction<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
  }) {
    _observer?.handleEvent(ActionDispatchedEvent(
      debugOrigin: debugOrigin ?? runtimeType.toString(),
      notifier: this,
      action: action,
    ));

    if (_overrides != null) {
      // Handle overrides
      final key = action.runtimeType;
      final override = _overrides![key];
      if (override != null) {
        // Use the override reducer
        final (T, R) temp = switch (override(state)) {
          T state => (state, null as R),
          (T, R) stateWithResult => stateWithResult,
          _ => throw Exception(
              'Invalid override reducer for ${action.runtimeType}'),
        };
        _setState(temp.$1, action);
        return temp;
      } else if (_overrides!.containsKey(key)) {
        // If the override is null (but the key exist),
        // we do not update the state.
        return (state, null as R);
      }
    }

    action.internalSetup(this);
    try {
      action.before();
      final newState = action.internalWrapReduce();
      _setState(newState.$1, action);
      return newState;
    } catch (e) {
      rethrow;
    } finally {
      try {
        action.after();
      } catch (e, st) {
        print('Error in after method of ${action.runtimeType}: $e\n$st');
      }
    }
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state.
  @protected
  @nonVirtual
  Future<T> dispatchAsync(
    AsyncReduxAction<BaseReduxNotifier<T>, T> action, {
    String? debugOrigin,
  }) async {
    final (state, _) =
        await _dispatchAsyncWithResult<void>(action, debugOrigin: debugOrigin);
    return state;
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state along with the result of the action.
  @protected
  @nonVirtual
  Future<(T, R)> dispatchAsyncWithResult<R>(
    AsyncReduxActionWithResult<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
  }) async {
    return _dispatchAsyncWithResult<R>(action, debugOrigin: debugOrigin);
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns only the result of the action.
  @protected
  @nonVirtual
  Future<R> dispatchAsyncTakeResult<R>(
    AsyncReduxActionWithResult<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
  }) async {
    final (_, result) = await _dispatchAsyncWithResult<R>(
      action,
      debugOrigin: debugOrigin,
    );
    return result;
  }

  @protected
  @nonVirtual
  Future<(T, R)> _dispatchAsyncWithResult<R>(
    AsynchronousReduxAction<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
  }) async {
    _observer?.handleEvent(ActionDispatchedEvent(
      debugOrigin: debugOrigin ?? runtimeType.toString(),
      notifier: this,
      action: action,
    ));

    if (_overrides != null) {
      // Handle overrides
      final key = action.runtimeType;
      final override = _overrides![key];
      if (override != null) {
        // Use the override reducer
        final (T, R) temp = switch (override(state)) {
          T state => (state, null as R),
          (T, R) stateWithResult => stateWithResult,
          _ => throw Exception(
              'Invalid override reducer for ${action.runtimeType}'),
        };
        _setState(temp.$1, action);
      } else if (_overrides!.containsKey(key)) {
        // If the override is null (but the key exist),
        // we do not update the state.
        return (state, null as R);
      }
    }

    action.internalSetup(this);

    try {
      await action.before();
      final newState = await action.internalWrapReduce();
      _setState(newState.$1, action);
      return newState;
    } catch (e) {
      rethrow;
    } finally {
      try {
        action.after();
      } catch (e, st) {
        print('Error in after method of ${action.runtimeType}: $e\n$st');
      }
    }
  }

  /// Overrides the reducer for the given action type.
  void _setOverrides(Map<Type, MockReducer<T>?> overrides) {
    _overrides = overrides;
  }

  @override
  @internal
  set state(T value) {
    throw UnsupportedError('Not allowed to set state directly');
  }

  /// Initializes the state of the notifier.
  /// This method is called only once and
  /// as soon as the notifier is accessed the first time.
  T init();

  @override
  @internal
  @mustCallSuper
  void internalSetup(RiverpieContainer container, RiverpieObserver? observer) {
    _listeners = NotifierListeners<T>(this, observer);
    _observer = observer;
    _initialized = true;
  }
}

/// A wrapper for [BaseSyncNotifier] that exposes [setState] and [state].
/// It creates a container internally, so any ref call still works.
/// This is useful for unit tests.
class TestableNotifier<N extends BaseSyncNotifier<T>, T> {
  TestableNotifier({
    required this.notifier,
    T? initialState,
  }) {
    notifier.internalSetup(RiverpieContainer(), null);
    if (initialState != null) {
      notifier._setState(initialState, null);
    } else {
      notifier._setState(notifier.init(), null);
    }
  }

  /// The wrapped notifier.
  final N notifier;

  /// Updates the state.
  void setState(T state) => notifier._setState(state, null);

  /// Gets the current state.
  T get state => notifier.state;
}

/// A wrapper for [BaseAsyncNotifier] that exposes [setState] and [state].
/// It creates a container internally, so any ref call still works.
/// This is useful for unit tests.
class TestableAsyncNotifier<N extends BaseAsyncNotifier<T>, T> {
  TestableAsyncNotifier({
    required this.notifier,
    AsyncValue<T>? initialState,
  }) {
    notifier.internalSetup(RiverpieContainer(), null);
    if (initialState != null) {
      notifier._futureCount++; // invalidate previous future callbacks
      notifier._setState(initialState, null);
    } else {
      notifier._setFutureAndListen(notifier.init());
    }
  }

  /// The wrapped notifier.
  final N notifier;

  /// Updates the state.
  void setState(AsyncValue<T> state) => notifier._setState(state, null);

  /// Sets the future.
  void setFuture(Future<T> future) => notifier._setFutureAndListen(future);

  /// Gets the current state.
  AsyncValue<T> get state => notifier.state;
}

/// A wrapper for [BaseReduxNotifier] that exposes [setState] and [state].
/// This is useful for unit tests.
class TestableReduxNotifier<T> {
  TestableReduxNotifier({
    required this.notifier,
    T? initialState,
  }) {
    if (initialState != null) {
      notifier._setState(initialState, null);
    }
  }

  /// The wrapped notifier.
  final BaseReduxNotifier<T> notifier;

  /// Dispatches an action and updates the state.
  /// Returns the new state.
  T dispatch(
    covariant ReduxAction<BaseReduxNotifier<T>, T> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatch(action, debugOrigin: debugOrigin);
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state.
  Future<T> dispatchAsync(
    covariant AsyncReduxAction<BaseReduxNotifier<T>, T> action, {
    String? debugOrigin,
  }) async {
    return notifier.dispatchAsync(action, debugOrigin: debugOrigin);
  }

  /// Updates the state without dispatching an action.
  void setState(T state) => notifier._setState(state, null);

  /// Gets the current state.
  T get state => notifier.state;
}

typedef MockReducer<T> = Object? Function(T state);

extension ReduxNotifierOverrideExt<N extends BaseReduxNotifier<T>, T,
    E extends Object> on ReduxProvider<N, T> {
  /// Overrides the reducer with the given [overrides].
  ///
  /// Usage:
  /// final ref = RiverpieContainer(
  ///   overrides: [
  ///     notifierProvider.overrideWithReducer(
  ///       overrides: {
  ///         MyAction: (state) => state + 1,
  ///         MyAnotherAction: null, // empty reducer
  ///         ...
  ///       },
  ///     ),
  ///   ],
  /// );
  ProviderOverride<N, T> overrideWithReducer({
    N Function(Ref ref)? notifier,
    required Map<Type, MockReducer<T>?> overrides,
  }) {
    return ProviderOverride<N, T>(
      provider: this,
      createState: (ref) {
        final createdNotifier = (notifier?.call(ref) ?? createState(ref));
        createdNotifier._setOverrides(overrides);
        return createdNotifier;
      },
    );
  }
}
