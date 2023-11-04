import 'dart:async';

import 'package:meta/meta.dart';
import 'package:refena/src/action/dispatcher.dart';
import 'package:refena/src/action/redux_action.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/container.dart';
import 'package:refena/src/notifier/listener.dart';
import 'package:refena/src/notifier/notifier_event.dart';
import 'package:refena/src/notifier/rebuildable.dart';
import 'package:refena/src/observer/event.dart';
import 'package:refena/src/observer/observer.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/types/redux_provider.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';
import 'package:refena/src/reference.dart';
import 'package:refena/src/util/batched_stream_controller.dart';
import 'package:refena/src/util/stacktrace.dart';

/// This enum controls the default behaviour of [updateShouldNotify].
/// Keep in mind that you can override [updateShouldNotify] in your notifiers
/// to implement a custom behaviour.
enum NotifyStrategy {
  /// Notify and rebuild whenever we have a new instance.
  /// Use this to avoid comparing deeply nested objects.
  identity,

  /// Notify and rebuild whenever the state in terms of equality (==) changes.
  /// This may result in less rebuilds.
  /// This is used as default.
  equality,
}

@internal
abstract class BaseNotifier<T> implements LabeledReference {
  bool _initialized = false;
  RefenaContainer? _container;
  RefenaObserver? _observer;
  final String? customDebugLabel;
  BaseProvider? _provider;
  NotifyStrategy? _notifyStrategy;
  bool _disposed = false;

  /// The current state of the notifier.
  /// It will be initialized by [init].
  @nonVirtual
  late T _state;

  /// A collection of listeners
  @nonVirtual
  final NotifierListeners<T> _listeners = NotifierListeners<T>();

  /// A collection of notifiers that this notifier depends on.
  final Set<BaseNotifier> dependencies = {};

  /// A collection of notifiers that depend on this notifier.
  /// They will be disposed when this notifier is disposed.
  final Set<BaseNotifier> dependents = {};

  /// Whether this notifier is disposed.
  bool get disposed => _disposed;

  BaseNotifier({String? debugLabel}) : customDebugLabel = debugLabel;

  /// The provider that created this notifier.
  /// This is only available after the initialization.
  @nonVirtual
  BaseProvider? get provider => _provider;

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
  void _setState(T value, BaseReduxAction? action) {
    if (!_initialized) {
      // We allow initializing the state before the initialization
      // by Refena is done.
      // The only drawback is that ref is not available during this phase.
      // Special providers like [FutureProvider] use this.
      _state = value;
      return;
    }

    final oldState = _state;
    _state = value;

    if (_initialized && updateShouldNotify(oldState, _state)) {
      final observer = _observer;
      if (observer != null) {
        final event = ChangeEvent<T>(
          notifier: this,
          action: action,
          prev: oldState,
          next: value,
          rebuild: [], // will be modified by notifyAll
        );
        _listeners.notifyAll(prev: oldState, next: _state, changeEvent: event);
        observer.internalHandleEvent(event);
      } else {
        _listeners.notifyAll(prev: oldState, next: _state);
      }
    }
  }

  /// This is called on [Ref.dispose].
  /// You can override this method to dispose resources.
  @protected
  void dispose() {}

  /// Override this if you want to a different kind of equality.
  @protected
  bool updateShouldNotify(T prev, T next) {
    switch (_notifyStrategy ?? NotifyStrategy.equality) {
      case NotifyStrategy.identity:
        return !identical(prev, next);
      case NotifyStrategy.equality:
        return prev != next;
    }
  }

  @override
  String get debugLabel => customDebugLabel ?? runtimeType.toString();

  /// Override this to provide a custom post initialization.
  /// The initial state is already set at this point.
  void postInit() {}

  /// Handles the actual initialization of the notifier.
  /// Calls [init] internally.
  @internal
  @mustCallSuper
  void internalSetup(
    ProxyRef ref,
    BaseProvider? provider,
  ) {
    _container = ref.container;
    _notifyStrategy = ref.container.defaultNotifyStrategy;
    _provider = provider;
    _observer = ref.container.observer;
  }

  /// Disposes the notifier.
  /// Returns a list of dependents that should be disposed as well.
  @internal
  @nonVirtual
  Set<BaseNotifier> internalDispose() {
    dispose();

    _disposed = true;
    _listeners.dispose();

    // Remove from dependency graph
    for (final dependency in dependencies) {
      dependency.dependents.remove(this);
    }

    return dependents;
  }

  @internal
  List<Rebuildable> getListeners() {
    return _listeners.getListeners();
  }

  @internal
  void cleanupListeners() {
    _listeners.removeUnusedListeners();
  }

  @internal
  void addListener(Rebuildable rebuildable, ListenerConfig<T> config) {
    _listeners.addListener(rebuildable, config);
  }

  @internal
  void removeListener(Rebuildable rebuildable) {
    _listeners.removeListener(rebuildable);
  }

  @internal
  Stream<NotifierEvent<T>> getStream() {
    return _listeners.getStream();
  }

  @override
  String toString() {
    return '$runtimeType(label: $debugLabel, state: ${_initialized ? _state : 'uninitialized'})';
  }

  /// Subclasses should not override this method.
  /// It is used internally by [dependencies] and [dependents].
  @override
  @nonVirtual
  bool operator ==(Object other) {
    return identical(this, other);
  }

  @override
  @nonVirtual
  int get hashCode => super.hashCode;
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
  void internalSetup(
    ProxyRef ref,
    BaseProvider? provider,
  ) {
    super.internalSetup(ref, provider);
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
    if (savePrev && state is AsyncData<T>) {
      _prev = state.data;
    }
    _setFutureAndListen(value);
  }

  T? _prev;

  /// The last valid state.
  /// If the future is loading or errored, this will be the previous state.
  /// If the future is completed, this will be the current data of the future.
  /// Manipulating the [state] directly will not update this value.
  T? get prev => _prev;

  /// Whether the previous state should be saved when setting the [future].
  /// Override this, if you don't want to save the previous state.
  /// Manipulating the [state] directly will ignore this flag.
  bool get savePrev => true;

  @nonVirtual
  void _setFutureAndListen(Future<T> value) async {
    _future = value;
    _futureCount++;
    state = AsyncValue<T>.loading(_prev);
    final currentCount = _futureCount; // after the setter, as it may change
    try {
      final value = await _future;
      if (currentCount != _futureCount) {
        // The future has been changed in the meantime.
        return;
      }
      state = AsyncValue.data(value);
      _prev = value; // drop the previous state
    } catch (error, stackTrace) {
      if (currentCount != _futureCount) {
        // The future has been changed in the meantime.
        return;
      }
      state = AsyncValue<T>.error(error, stackTrace, _prev);
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
  void internalSetup(
    ProxyRef ref,
    BaseProvider? provider,
  ) {
    super.internalSetup(ref, provider);

    // do not set future directly, as the setter may be overridden
    _setFutureAndListen(init());

    _initialized = true;
  }
}

final class ViewProviderNotifier<T> extends BaseSyncNotifier<T>
    implements Rebuildable {
  ViewProviderNotifier(this._builder, {super.debugLabel});

  late final WatchableRef _watchableRef;
  final T Function(WatchableRef) _builder;
  final _rebuildController = BatchedStreamController<AbstractChangeEvent>();

  @override
  T init() {
    _rebuildController.stream.listen((event) {
      // rebuild notifier state
      _setStateCustom(
        _build(),
        event,
      );
    });
    return _build();
  }

  T _build() {
    final oldDependencies = {...dependencies};
    dependencies.clear();

    final nextState = (_watchableRef as WatchableRefImpl).trackNotifier(
      onAccess: (notifier) {
        dependencies.add(notifier);
        notifier.dependents.add(this);
      },
      run: () => _builder(_watchableRef),
    );

    final removedDependencies = oldDependencies.difference(dependencies);
    for (final removedDependency in removedDependencies) {
      // remove from dependency graph
      removedDependency.dependents.remove(this);

      // remove listener to avoid future rebuilds
      removedDependency._listeners.removeListener(this);
    }

    return nextState;
  }

  // See [BaseNotifier._setState] for reference.
  void _setStateCustom(T value, List<AbstractChangeEvent> causes) {
    if (!_initialized) {
      _state = value;
      return;
    }

    final oldState = _state;
    _state = value;

    if (_initialized && updateShouldNotify(oldState, _state)) {
      final observer = _observer;
      if (observer != null) {
        final event = RebuildEvent<T>(
          rebuildable: this,
          causes: causes,
          prev: oldState,
          next: value,
          rebuild: [], // will be modified by notifyAll
        );
        _listeners.notifyAll(prev: oldState, next: _state, rebuildEvent: event);
        observer.internalHandleEvent(event);
      } else {
        _listeners.notifyAll(prev: oldState, next: _state);
      }
    }
  }

  @internal
  @override
  void internalSetup(
    ProxyRef ref,
    BaseProvider? provider,
  ) {
    _watchableRef = WatchableRefImpl(
      container: ref.container,
      rebuildable: this,
    );

    super.internalSetup(ref, provider);
  }

  @override
  void rebuild(ChangeEvent? changeEvent, RebuildEvent? rebuildEvent) {
    assert(
      changeEvent == null || rebuildEvent == null,
      'Cannot have both changeEvent and rebuildEvent',
    );

    if (changeEvent != null) {
      _rebuildController.schedule(changeEvent);
    } else if (rebuildEvent != null) {
      _rebuildController.schedule(rebuildEvent);
    } else {
      _rebuildController.schedule(null);
    }
  }

  @override
  @nonVirtual
  void dispose() {
    _rebuildController.dispose();
  }

  @override
  bool get disposed => _disposed;

  @override
  void onDisposeWidget() {}

  @override
  void notifyListenerTarget(BaseNotifier notifier) {}

  @override
  bool get isWidget => false;
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
  BaseReduxNotifier({super.debugLabel});

  /// A map of overrides for the reducers.
  Map<Type, MockReducer<T>?>? _overrides;

  /// WatchActions that belong to this notifier.
  /// They will be cancelled when the notifier is disposed.
  final List<WatchActionSubscription> _watchActions = [];

  /// The override for the initial state.
  T? _overrideInitialState;

  /// Access the [Dispatcher] of this notifier.
  late final redux = Dispatcher<BaseReduxNotifier<T>, T>(
    notifier: this,
    debugOrigin: debugLabel,
    debugOriginRef: this,
  );

  /// Creates a [Dispatcher] for an external notifier.
  Dispatcher<BaseReduxNotifier<T2>, T2> external<T2>(
    BaseReduxNotifier<T2> notifier,
  ) {
    return Dispatcher<BaseReduxNotifier<T2>, T2>(
      notifier: notifier,
      debugOrigin: debugLabel,
      debugOriginRef: this,
    );
  }

  /// Dispatches an action and updates the state.
  /// Returns the new state.
  ///
  /// For library consumers, use:
  /// - [BaseReduxAction.external] to dispatch external actions.
  /// - [external] to dispatch external actions inside the notifier.
  /// - [redux] to dispatch internal actions inside the notifier.
  @internal
  @nonVirtual
  T dispatch(
    SynchronousReduxAction<BaseReduxNotifier<T>, T, dynamic> action, {
    String? debugOrigin,
    LabeledReference? debugOriginRef,
  }) {
    return _dispatchWithResult<dynamic>(
      action,
      debugOrigin: debugOrigin,
      debugOriginRef: debugOriginRef,
    ).$1;
  }

  /// Dispatches an action and updates the state.
  /// Returns the new state along with the result of the action.
  ///
  /// For library consumers, use:
  /// - [BaseReduxAction.external] to dispatch external actions.
  /// - [external] to dispatch external actions inside the notifier.
  /// - [redux] to dispatch internal actions inside the notifier.
  @internal
  @nonVirtual
  (T, R) dispatchWithResult<R>(
    BaseReduxActionWithResult<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
    LabeledReference? debugOriginRef,
  }) {
    return _dispatchWithResult<R>(
      action,
      debugOrigin: debugOrigin,
      debugOriginRef: debugOriginRef,
    );
  }

  /// Dispatches an action and updates the state.
  /// Returns only the result of the action.
  ///
  /// For library consumers, use:
  /// - [BaseReduxAction.external] to dispatch external actions.
  /// - [external] to dispatch external actions inside the notifier.
  /// - [redux] to dispatch internal actions inside the notifier.
  @internal
  @nonVirtual
  R dispatchTakeResult<R>(
    BaseReduxActionWithResult<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
    LabeledReference? debugOriginRef,
  }) {
    return _dispatchWithResult<R>(
      action,
      debugOrigin: debugOrigin,
      debugOriginRef: debugOriginRef,
    ).$2;
  }

  @nonVirtual
  (T, R) _dispatchWithResult<R>(
    SynchronousReduxAction<BaseReduxNotifier<T>, T, R> action, {
    required String? debugOrigin,
    required LabeledReference? debugOriginRef,
  }) {
    _observer?.internalHandleEvent(ActionDispatchedEvent(
      debugOrigin: debugOrigin ?? runtimeType.toString(),
      debugOriginRef: action.trackOrigin ? (debugOriginRef ?? this) : this,
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
        _observer?.internalHandleEvent(ActionFinishedEvent(
          action: action,
          result: temp.$2,
        ));
        return temp;
      } else if (_overrides!.containsKey(key)) {
        // If the override is null (but the key exist),
        // we do not update the state.
        return (state, null as R);
      }
    }

    action.internalSetup(_container, this, _observer);
    try {
      try {
        action.before();
      } catch (error, stackTrace) {
        _observer?.internalHandleEvent(ActionErrorEvent(
          action: action,
          lifecycle: ActionLifecycle.before,
          error: error,
          stackTrace: stackTrace,
        ));
        rethrow;
      }

      try {
        final newState = action.internalWrapReduce();
        _setState(newState.$1, action);
        _observer?.internalHandleEvent(ActionFinishedEvent(
          action: action,
          result: newState.$2,
        ));
        return newState;
      } catch (error, stackTrace) {
        _observer?.internalHandleEvent(ActionErrorEvent(
          action: action,
          lifecycle: ActionLifecycle.reduce,
          error: error,
          stackTrace: stackTrace,
        ));
        rethrow;
      }
    } catch (error) {
      rethrow;
    } finally {
      try {
        action.after();
      } catch (error, stackTrace) {
        _observer?.internalHandleEvent(ActionErrorEvent(
          action: action,
          lifecycle: ActionLifecycle.after,
          error: error,
          stackTrace: stackTrace,
        ));
      }
    }
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state.
  ///
  /// For library consumers, use:
  /// - [BaseReduxAction.external] to dispatch external actions.
  /// - [external] to dispatch external actions inside the notifier.
  /// - [redux] to dispatch internal actions inside the notifier.
  @internal
  @nonVirtual
  Future<T> dispatchAsync(
    AsynchronousReduxAction<BaseReduxNotifier<T>, T, dynamic> action, {
    String? debugOrigin,
    LabeledReference? debugOriginRef,
  }) async {
    final (state, _) = await _dispatchAsyncWithResult<dynamic>(
      action,
      debugOrigin: debugOrigin,
      debugOriginRef: debugOriginRef,
    );
    return state;
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state along with the result of the action.
  ///
  /// For library consumers, use:
  /// - [BaseReduxAction.external] to dispatch external actions.
  /// - [external] to dispatch external actions inside the notifier.
  /// - [redux] to dispatch internal actions inside the notifier.
  @internal
  @nonVirtual
  Future<(T, R)> dispatchAsyncWithResult<R>(
    BaseAsyncReduxActionWithResult<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
    LabeledReference? debugOriginRef,
  }) {
    return _dispatchAsyncWithResult<R>(
      action,
      debugOrigin: debugOrigin,
      debugOriginRef: debugOriginRef,
    );
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns only the result of the action.
  ///
  /// For library consumers, use:
  /// - [BaseReduxAction.external] to dispatch external actions.
  /// - [external] to dispatch external actions inside the notifier.
  /// - [redux] to dispatch internal actions inside the notifier.
  @internal
  @nonVirtual
  Future<R> dispatchAsyncTakeResult<R>(
    BaseAsyncReduxActionWithResult<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
    LabeledReference? debugOriginRef,
  }) async {
    final (_, result) = await _dispatchAsyncWithResult<R>(
      action,
      debugOrigin: debugOrigin,
      debugOriginRef: debugOriginRef,
    );
    return result;
  }

  @nonVirtual
  Future<(T, R)> _dispatchAsyncWithResult<R>(
    AsynchronousReduxAction<BaseReduxNotifier<T>, T, R> action, {
    required String? debugOrigin,
    required LabeledReference? debugOriginRef,
  }) async {
    _observer?.internalHandleEvent(ActionDispatchedEvent(
      debugOrigin: debugOrigin ?? runtimeType.toString(),
      debugOriginRef: action.trackOrigin ? (debugOriginRef ?? this) : this,
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
        _observer?.internalHandleEvent(ActionFinishedEvent(
          action: action,
          result: temp.$2,
        ));
      } else if (_overrides!.containsKey(key)) {
        // If the override is null (but the key exist),
        // we do not update the state.
        return (state, null as R);
      }
    }

    action.internalSetup(_container, this, _observer);

    try {
      try {
        await action.before();
      } catch (error, stackTrace) {
        final extendedStackTrace = extendStackTrace(stackTrace);
        _observer?.internalHandleEvent(ActionErrorEvent(
          action: action,
          lifecycle: ActionLifecycle.before,
          error: error,
          stackTrace: extendedStackTrace,
        ));
        Error.throwWithStackTrace(
          error,
          extendedStackTrace,
        );
      }

      try {
        final newState = await action.internalWrapReduce();
        _setState(newState.$1, action);
        _observer?.internalHandleEvent(ActionFinishedEvent(
          action: action,
          result: newState.$2,
        ));
        return newState;
      } catch (error, stackTrace) {
        final extendedStackTrace = extendStackTrace(stackTrace);
        _observer?.internalHandleEvent(ActionErrorEvent(
          action: action,
          lifecycle: ActionLifecycle.reduce,
          error: error,
          stackTrace: extendedStackTrace,
        ));
        Error.throwWithStackTrace(
          error,
          extendedStackTrace,
        );
      }
    } catch (e) {
      rethrow;
    } finally {
      try {
        action.after();
      } catch (error, stackTrace) {
        _observer?.internalHandleEvent(ActionErrorEvent(
          action: action,
          lifecycle: ActionLifecycle.after,
          error: error,
          stackTrace: stackTrace,
        ));
      }
    }
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

  /// Override this to provide a custom action that will be
  /// dispatched when the notifier is initialized.
  BaseReduxAction<BaseReduxNotifier<T>, T, dynamic>? get initialAction => null;

  SynchronousReduxAction<BaseReduxNotifier<T>, T, dynamic>? get disposeAction =>
      null;

  @override
  void postInit() {
    switch (initialAction) {
      case SynchronousReduxAction<BaseReduxNotifier<T>, T, dynamic> action:
        dispatch(action);
        break;
      case AsynchronousReduxAction<BaseReduxNotifier<T>, T, dynamic> action:
        dispatchAsync(action);
        break;
      case null:
        break;
      default:
        print(
          'Invalid initialAction type for $debugLabel: ${initialAction.runtimeType}',
        );
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    final disposeAction = this.disposeAction;
    if (disposeAction != null) {
      dispatch(disposeAction);
    }
    for (final watchAction in _watchActions) {
      watchAction.cancel();
    }
    super.dispose();
  }

  @override
  @internal
  @mustCallSuper
  void internalSetup(
    ProxyRef ref,
    BaseProvider? provider,
  ) {
    super.internalSetup(ref, provider);
    _state = _overrideInitialState ?? init();
    _initialized = true;
  }

  @internal
  @nonVirtual
  void registerWatchAction(WatchActionSubscription subscription) {
    _watchActions.add(subscription);
    _watchActions.removeWhere((s) => s.disposed);
  }
}

/// A wrapper for [BaseSyncNotifier] that exposes [setState] and [state].
/// It creates a container internally, so any ref call still works.
/// This is useful for unit tests.
class NotifierTester<N extends BaseSyncNotifier<T>, T> {
  NotifierTester({
    required this.notifier,
    T? initialState,
  }) {
    notifier.internalSetup(
      ProxyRef(
        RefenaContainer(),
        'NotifierTester',
        LabeledReference.custom('NotifierTester'),
      ),
      null,
    );
    if (initialState != null) {
      notifier._state = initialState;
    } else {
      notifier._state = notifier.init();
    }
    notifier.postInit();
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
class AsyncNotifierTester<N extends BaseAsyncNotifier<T>, T> {
  AsyncNotifierTester({
    required this.notifier,
    AsyncValue<T>? initialState,
  }) {
    notifier.internalSetup(
      ProxyRef(
        RefenaContainer(),
        'AsyncNotifierTester',
        LabeledReference.custom('AsyncNotifierTester'),
      ),
      null,
    );
    if (initialState != null) {
      notifier._futureCount++; // invalidate previous future callbacks
      notifier._state = initialState;
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
class ReduxNotifierTester<T> {
  ReduxNotifierTester({
    required this.notifier,
    bool runInitialAction = false,
    T? initialState,
  }) {
    if (initialState != null) {
      notifier._state = initialState;
    } else {
      notifier._state = notifier.init();
    }

    if (runInitialAction) {
      notifier.postInit();
    }
  }

  /// The wrapped notifier.
  final BaseReduxNotifier<T> notifier;

  /// Dispatches an action and updates the state.
  /// Returns the new state.
  T dispatch(
    SynchronousReduxAction<BaseReduxNotifier<T>, T, dynamic> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatch(action, debugOrigin: debugOrigin);
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state.
  Future<T> dispatchAsync(
    AsynchronousReduxAction<BaseReduxNotifier<T>, T, dynamic> action, {
    String? debugOrigin,
  }) async {
    return notifier.dispatchAsync(action, debugOrigin: debugOrigin);
  }

  /// Dispatches an action and updates the state.
  /// Returns the new state along with the result of the action.
  (T, R) dispatchWithResult<R>(
    BaseReduxActionWithResult<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchWithResult(action, debugOrigin: debugOrigin);
  }

  /// Dispatches an action and updates the state.
  /// Returns only the result of the action.
  R dispatchTakeResult<R>(
    BaseReduxActionWithResult<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchTakeResult(action, debugOrigin: debugOrigin);
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state along with the result of the action.
  Future<(T, R)> dispatchAsyncWithResult<R>(
    BaseAsyncReduxActionWithResult<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchAsyncWithResult(action, debugOrigin: debugOrigin);
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns only the result of the action.
  Future<R> dispatchAsyncTakeResult<R>(
    BaseAsyncReduxActionWithResult<BaseReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchAsyncTakeResult(action, debugOrigin: debugOrigin);
  }

  /// Updates the state without dispatching an action.
  void setState(T state) => notifier._setState(state, null);

  /// Gets the current state.
  T get state => notifier.state;
}

/// Function type for a mocked reducer.
typedef MockReducer<T> = Object? Function(T state);

/// Function type for a mocked global reducer.
typedef MockGlobalReducer = void Function(Ref ref);

extension ReduxNotifierOverrideExt<N extends BaseReduxNotifier<T>, T>
    on ReduxProvider<N, T> {
  /// Overrides the reducer with the given [overrides].
  ///
  /// Usage:
  /// final ref = RefenaContainer(
  ///   overrides: [
  ///     notifierProvider.overrideWithReducer(
  ///       reducer: {
  ///         MyAction: (state) => state + 1,
  ///         MyAnotherAction: null, // empty reducer
  ///         ...
  ///       },
  ///     ),
  ///   ],
  /// );
  ProviderOverride<N, T> overrideWithReducer({
    N Function(Ref ref)? notifier,
    T? initialState,
    required Map<Type, MockReducer<T>?> reducer,
  }) {
    return ProviderOverride<N, T>(
      provider: this,
      createState: (ref) {
        final createdNotifier = (notifier?.call(ref) ?? createState(ref));
        createdNotifier._overrideInitialState = initialState;
        createdNotifier._overrides = reducer;
        return createdNotifier;
      },
    );
  }

  /// Overrides the initial state with the given [initialState].
  ProviderOverride<N, T> overrideWithInitialState({
    N Function(Ref ref)? notifier,
    required T? initialState,
  }) {
    return ProviderOverride<N, T>(
      provider: this,
      createState: (ref) {
        final createdNotifier = (notifier?.call(ref) ?? createState(ref));
        createdNotifier._overrideInitialState = initialState;
        return createdNotifier;
      },
    );
  }
}

extension GlobalReduxNotifierOverrideExt on ReduxProvider<GlobalRedux, void> {
  /// A special override for global actions.
  ///
  /// Usage:
  /// final ref = RefenaContainer(
  ///   overrides: [
  ///     globalReduxProvider.overrideWithGlobalReducer(
  ///       reducer: {
  ///         MyAction: (ref) => ref.read(myProvider).increment(),
  ///         MyAnotherAction: null, // empty reducer
  ///         ...
  ///       },
  ///     ),
  ///   ],
  /// );
  ProviderOverride<GlobalRedux, void> overrideWithGlobalReducer({
    required Map<Type, MockGlobalReducer?> reducer,
  }) {
    return ProviderOverride<GlobalRedux, void>(
      provider: this,
      createState: (ref) {
        final createdNotifier = GlobalRedux();
        createdNotifier._overrides = {
          for (final entry in reducer.entries)
            entry.key: entry.value == null
                ? null
                : (state) {
                    entry.value!(ref);
                    return null;
                  },
        };
        return createdNotifier;
      },
    );
  }
}
