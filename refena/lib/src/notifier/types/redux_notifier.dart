part of '../base_notifier.dart';

/// A notifier where the state is updated by dispatching actions.
///
/// You do not have access to [Ref] in this notifier, so you need to pass
/// the required dependencies via constructor.
///
/// From outside, you should dispatch actions with
/// `ref.redux(provider).dispatch(action)`.
///
/// Dispatching inside the notifier is discouraged because you
/// will lose the origin.
/// In edge cases, you can use `this.redux.dispatch(action)`.
///
/// {@category Redux}
abstract class ReduxNotifier<T> extends BaseNotifier<T> {
  ReduxNotifier();

  /// A map of overrides for the reducers.
  Map<Type, MockReducer<T>?>? _overrides;

  /// WatchActions that belong to this notifier.
  /// They will be cancelled when the notifier is disposed.
  final List<WatchActionSubscription> _watchActions = [];

  /// The override for the initial state.
  T? _overrideInitialState;

  /// Access the [Dispatcher] of this notifier.
  late final redux = Dispatcher<ReduxNotifier<T>, T>(
    notifier: this,
    debugOrigin: debugLabel,
    debugOriginRef: this,
  );

  /// Creates a [Dispatcher] for an external notifier.
  Dispatcher<ReduxNotifier<T2>, T2> external<T2>(
    ReduxNotifier<T2> notifier,
  ) {
    return Dispatcher<ReduxNotifier<T2>, T2>(
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
    SynchronousReduxAction<ReduxNotifier<T>, T, dynamic> action, {
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
    BaseReduxActionWithResult<ReduxNotifier<T>, T, R> action, {
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
    BaseReduxActionWithResult<ReduxNotifier<T>, T, R> action, {
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
    SynchronousReduxAction<ReduxNotifier<T>, T, R> action, {
    required String? debugOrigin,
    required LabeledReference? debugOriginRef,
  }) {
    _observer?.dispatchEvent(ActionDispatchedEvent(
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
        _observer?.dispatchEvent(ActionFinishedEvent(
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
        _observer?.dispatchEvent(ActionErrorEvent(
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
        _observer?.dispatchEvent(ActionFinishedEvent(
          action: action,
          result: newState.$2,
        ));
        return newState;
      } catch (error, stackTrace) {
        _observer?.dispatchEvent(ActionErrorEvent(
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
        _observer?.dispatchEvent(ActionErrorEvent(
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
    AsynchronousReduxAction<ReduxNotifier<T>, T, dynamic> action, {
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
    BaseAsyncReduxActionWithResult<ReduxNotifier<T>, T, R> action, {
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
    BaseAsyncReduxActionWithResult<ReduxNotifier<T>, T, R> action, {
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
    AsynchronousReduxAction<ReduxNotifier<T>, T, R> action, {
    required String? debugOrigin,
    required LabeledReference? debugOriginRef,
  }) async {
    _observer?.dispatchEvent(ActionDispatchedEvent(
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
        _observer?.dispatchEvent(ActionFinishedEvent(
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
        _observer?.dispatchEvent(ActionErrorEvent(
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
        // Warning:
        // In normal cases, the assignment after the return statement
        // is executed synchronously.
        //
        // If the future is a completed future
        // (e.g. async function without microtask),
        // there is a microtask between the return statement and the await
        // resulting in a possible race condition if there is another
        // regular future action finishing in the same microtask.
        //
        // Completed Future: Return -> Microtask -> Result notified
        // Regular Future: Return -> Result notified
        final newState = await action.internalWrapReduce();
        _setState(newState.$1, action);
        _observer?.dispatchEvent(ActionFinishedEvent(
          action: action,
          result: newState.$2,
        ));
        return newState;
      } catch (error, stackTrace) {
        final extendedStackTrace = extendStackTrace(stackTrace);
        _observer?.dispatchEvent(ActionErrorEvent(
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
        _observer?.dispatchEvent(ActionErrorEvent(
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
  BaseReduxAction<ReduxNotifier<T>, T, dynamic>? get initialAction => null;

  SynchronousReduxAction<ReduxNotifier<T>, T, dynamic>? get disposeAction =>
      null;

  @override
  void postInit() {
    super.postInit();
    switch (initialAction) {
      case SynchronousReduxAction<ReduxNotifier<T>, T, dynamic> action:
        dispatch(action);
        break;
      case AsynchronousReduxAction<ReduxNotifier<T>, T, dynamic> action:
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
    BaseProvider<BaseNotifier<T>, T>? provider,
  ) {
    super.internalSetup(ref, provider);
    _state = _overrideInitialState ?? init();
    _initialized = true;

    _setupOnChanged(ref.container, provider);
  }

  /// Registers a [WatchAction] so it can be later disposed
  /// when the notifier is disposed.
  @internal
  @nonVirtual
  void registerWatchAction(WatchActionSubscription subscription) {
    _watchActions.add(subscription);
    _watchActions.removeWhere((s) => s.disposed);
  }

  /// Returns a debug version of the [notifier] where
  /// you can set the state directly and dispatch actions
  ///
  /// Usage:
  /// final counter = ReduxNotifier.test(
  ///   redux: Counter(),
  ///   initialState: 11,
  /// );
  ///
  /// expect(counter.state, 11);
  /// counter.dispatch(IncrementAction());
  static ReduxNotifierTester<T> test<T, E extends Object>({
    required ReduxNotifier<T> redux,
    bool runInitialAction = false,
    T? initialState,
  }) {
    return ReduxNotifierTester(
      notifier: redux,
      runInitialAction: runInitialAction,
      initialState: initialState,
    );
  }
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
  final ReduxNotifier<T> notifier;

  /// Dispatches an action and updates the state.
  /// Returns the new state.
  T dispatch(
    SynchronousReduxAction<ReduxNotifier<T>, T, dynamic> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatch(action, debugOrigin: debugOrigin);
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state.
  Future<T> dispatchAsync(
    AsynchronousReduxAction<ReduxNotifier<T>, T, dynamic> action, {
    String? debugOrigin,
  }) async {
    return notifier.dispatchAsync(action, debugOrigin: debugOrigin);
  }

  /// Dispatches an action and updates the state.
  /// Returns the new state along with the result of the action.
  (T, R) dispatchWithResult<R>(
    BaseReduxActionWithResult<ReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchWithResult(action, debugOrigin: debugOrigin);
  }

  /// Dispatches an action and updates the state.
  /// Returns only the result of the action.
  R dispatchTakeResult<R>(
    BaseReduxActionWithResult<ReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchTakeResult(action, debugOrigin: debugOrigin);
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns the new state along with the result of the action.
  Future<(T, R)> dispatchAsyncWithResult<R>(
    BaseAsyncReduxActionWithResult<ReduxNotifier<T>, T, R> action, {
    String? debugOrigin,
  }) {
    return notifier.dispatchAsyncWithResult(action, debugOrigin: debugOrigin);
  }

  /// Dispatches an asynchronous action and updates the state.
  /// Returns only the result of the action.
  Future<R> dispatchAsyncTakeResult<R>(
    BaseAsyncReduxActionWithResult<ReduxNotifier<T>, T, R> action, {
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

extension ReduxNotifierOverrideExt<N extends ReduxNotifier<T>, T>
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
