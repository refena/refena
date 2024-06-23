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
import 'package:refena/src/provider/watchable.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';
import 'package:refena/src/reference.dart';
import 'package:refena/src/util/batched_stream_controller.dart';
import 'package:refena/src/util/stacktrace.dart';

part 'types/family_notifier.dart';

part 'types/future_provider_notifier.dart';

part 'types/redux_notifier.dart';

part 'types/stream_provider_notifier.dart';

part 'types/view_provider_notifier.dart';

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
  BaseNotifier();

  @nonVirtual
  bool _initialized = false;

  @nonVirtual
  RefenaContainer? _container;

  @nonVirtual
  RefenaObserver? _observer;

  @nonVirtual
  BaseProvider<BaseNotifier<T>, T>? _provider;

  @nonVirtual
  NotifyStrategy? _notifyStrategy;

  /// A special listener that is unique to the notifier.
  /// Provided by the `onChanged` callback in the provider constructor.
  @nonVirtual
  OnChangedListenerCallback<T>? _onChangedListener;

  @nonVirtual
  bool _disposed = false;

  /// The current state of the notifier.
  /// It will be initialized by [init].
  @nonVirtual
  late T _state;

  /// A collection of listeners
  @nonVirtual
  final NotifierListeners<T> _listeners = NotifierListeners<T>();

  /// A collection of notifiers that this notifier depends on.
  @nonVirtual
  final Set<BaseNotifier> dependencies = {};

  /// A collection of notifiers that depend on this notifier.
  /// They will be disposed when this notifier is disposed.
  @nonVirtual
  final Set<BaseNotifier> dependents = {};

  /// Whether disposing this notifier should also dispose the dependents.
  /// If this is true, the [dependents] are considered to be fake.
  @nonVirtual
  bool _fakeDependents = false;

  /// Whether this notifier is disposed.
  bool get disposed => _disposed;

  /// The provider that created this notifier.
  /// This is only available after the initialization.
  @nonVirtual
  BaseProvider<BaseNotifier<T>, T>? get provider => _provider;

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
  @nonVirtual
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
          // will be modified by notifyAll
          rebuild: [],
        );
        _listeners.notifyAll(prev: oldState, next: value, changeEvent: event);
        observer.dispatchEvent(event);

        // trigger onChanged **after** the ChangeEvent
        _onChangedListener?.call(oldState, value, event, null);
      } else {
        _listeners.notifyAll(prev: oldState, next: value);
      }
    }
  }

  /// Similar to [_setState],
  /// but a [RebuildEvent] event is dispatched to the observer instead.
  @nonVirtual
  void _setStateAsRebuild(
    Rebuildable rebuildable,
    T value,
    List<AbstractChangeEvent> causes,
    LabeledReference? debugOrigin,
  ) {
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
          rebuildable: rebuildable,
          causes: causes,
          prev: oldState,
          next: value,
          // will be modified by notifyAll
          rebuild: [],
          debugOrigin: debugOrigin,
        );
        _listeners.notifyAll(prev: oldState, next: _state, rebuildEvent: event);
        observer.dispatchEvent(event);
        // trigger onChanged **after** the RebuildEvent
        _onChangedListener?.call(oldState, value, null, event);
      } else {
        _listeners.notifyAll(prev: oldState, next: _state);
      }
    }
  }

  /// This is called on [Ref.dispose].
  /// You can override this method to dispose resources.
  @protected
  @mustCallSuper
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

  /// Override this to provide a customized description of the state.
  /// This is used by the built-in observers for improved logging.
  @useResult
  String describeState(T state) => state.toString();

  @override
  @nonVirtual
  String get debugLabel => customDebugLabel ?? runtimeType.toString();

  /// Override this to provide a custom debug label.
  String? get customDebugLabel => _customDebugLabel;

  @nonVirtual
  String? _customDebugLabel;

  /// Override this to provide a custom post initialization.
  /// The initial state is already set at this point.
  @mustCallSuper
  void postInit() {}

  /// Handles the actual initialization of the notifier.
  /// Calls [init] internally.
  @internal
  @mustCallSuper
  void internalSetup(
    ProxyRef ref,
    BaseProvider<BaseNotifier<T>, T>? provider,
  ) {
    _container = ref.container;
    _notifyStrategy = ref.container.defaultNotifyStrategy;
    _provider = provider;
    _observer = ref.container.observer;

    // Prefer the custom debug label from the provider
    final providerDebugLabel = provider?.customDebugLabel;
    if (providerDebugLabel != null && _customDebugLabel == null) {
      _customDebugLabel = providerDebugLabel;
    }
  }

  @internal
  @nonVirtual
  List<Rebuildable> getListeners() {
    return _listeners.getListeners();
  }

  @internal
  @nonVirtual
  void cleanupListeners() {
    _listeners.removeDisposedListeners();
  }

  @internal
  @nonVirtual
  void addListener(Rebuildable rebuildable, ListenerConfig<T> config) {
    _listeners.addListener(rebuildable, config);
  }

  @internal
  @nonVirtual
  void removeListener(Rebuildable rebuildable) {
    _listeners.removeListener(rebuildable);
  }

  @internal
  @nonVirtual
  Stream<NotifierEvent<T>> getStream() {
    return _listeners.getStream();
  }

  /// If this is true, initializing must be done by ViewModelBuilder of the refena_flutter package.
  /// This flag is needed to throw an exception if the user forgets to use ViewModelBuilder.
  @internal
  bool get requireBuildContext => false;

  /// Starts listening to the stream
  /// and calls [InternalBaseProviderExt.onChanged] whenever the state changes.
  @nonVirtual
  void _setupOnChanged(
    RefenaContainer container,
    BaseProvider<BaseNotifier<T>, T>? provider,
  ) {
    final onChanged = provider?.onChanged;
    if (onChanged != null) {
      _onChangedListener = (prev, next, changeEvent, rebuildEvent) {
        final onChangedRef = ProxyRef(
          container,
          changeEvent?.debugLabel ??
              rebuildEvent?.debugLabel ??
              customDebugLabel ??
              provider?.debugLabel ??
              runtimeType.toString(),
          changeEvent ?? rebuildEvent ?? provider ?? this,
        );
        onChanged(prev, next, onChangedRef);
      };
    }
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
extension InternalBaseNotifierExt<T> on BaseNotifier<T> {
  /// Disposes the notifier.
  /// Returns a list of dependents that should be disposed as well.
  Set<BaseNotifier> internalDispose() {
    dispose();

    _disposed = true;
    _listeners.dispose();
    _onChangedListener = null;

    // Remove from dependency graph
    for (final dependency in dependencies) {
      dependency.dependents.remove(this);
    }

    if (_fakeDependents) {
      return {};
    }

    return dependents;
  }

  /// Sets the custom debug label.
  /// This is usually set by the library if
  /// the notifier is not exposed to the user (e.g. [FutureProvider]).
  void setCustomDebugLabel(String label) {
    _customDebugLabel = label;
  }
}

@internal
abstract class BaseSyncNotifier<T> extends BaseNotifier<T> {
  BaseSyncNotifier();

  /// Initializes the state of the notifier.
  /// This method is called only once and
  /// as soon as the notifier is accessed the first time.
  T init();

  @override
  @internal
  @mustCallSuper
  void internalSetup(
    ProxyRef ref,
    BaseProvider<BaseNotifier<T>, T>? provider,
  ) {
    super.internalSetup(ref, provider);
    _state = init();
    _initialized = true;

    _setupOnChanged(ref.container, provider);
  }
}

@internal
abstract class BaseAsyncNotifier<T> extends BaseNotifier<AsyncValue<T>>
    implements GetFutureNotifier<T> {
  BaseAsyncNotifier();

  @nonVirtual
  late Future<T> _future;

  @nonVirtual
  int _futureCount = 0;

  @override
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
    BaseProvider<BaseNotifier<AsyncValue<T>>, AsyncValue<T>>? provider,
  ) {
    super.internalSetup(ref, provider);

    // do not set future directly, as the setter may be overridden
    _setFutureAndListen(init());

    _initialized = true;

    _setupOnChanged(ref.container, provider);
  }
}

String _describeMapState<T, P>(
  Map<P, T> state,
  String Function(T state) describe,
) {
  return state.entries.map((e) => '${e.key}: ${describe(e.value)}').join(', ');
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

/// A notifier that exposes a [future].
abstract interface class GetFutureNotifier<T>
    implements BaseNotifier<AsyncValue<T>> {
  /// The future.
  Future<T> get future;
}

/// A notifier that can be rebuilt.
/// In other words: The provider build lambda can be called again without
/// the notifier being disposed.
///
/// [T] is the state type.
/// [R] is the return type of [_builder].
mixin RebuildableNotifier<T, R> on BaseNotifier<T> implements Rebuildable {
  late final WatchableRefImpl _watchableRef;
  final _rebuildController = BatchedStreamController<AbstractChangeEvent>();

  /// Will be called on rebuild.
  /// Subclasses should override this method.
  R Function(WatchableRef ref) get _builder;

  /// Calls [_builder] and tracks all accessed notifiers.
  /// Returns the result of [_builder].
  @nonVirtual
  R _callAndSetDependencies() {
    final oldDependencies = {...dependencies};
    dependencies.clear();

    final R nextState = _watchableRef.trackNotifier(
      onAccess: (notifier) {
        final added = dependencies.add(notifier);
        if (!added) {
          printAlreadyWatchedWarning(
            rebuildable: this,
            notifier: notifier,
          );
        }
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

  /// Similar to [_callAndSetDependencies],
  /// but the listener stays active until
  /// [RefDependencyListener.cancel] is called.
  ///
  /// This is used by futures and streams because the dependencies
  /// may not known in advance.
  @nonVirtual
  RefDependencyListener<R> _callAndListenDependencies() {
    // Clear old dependencies
    for (final dependency in dependencies) {
      // remove from dependency graph
      dependency.dependents.remove(this);

      // remove listener to avoid future rebuilds
      dependency._listeners.removeListener(this);
    }
    dependencies.clear();

    final tempRef = WatchableRefImpl(
      container: _watchableRef.container,
      rebuildable: this,
    );
    tempRef.startNotifierTracking(onAccess: _addNotifierDependency);

    return RefDependencyListener(_builder(tempRef), () {
      tempRef.stopNotifierTracking();
    });
  }

  void _addNotifierDependency(BaseNotifier notifier) {
    final added = dependencies.add(notifier);
    if (!added) {
      printAlreadyWatchedWarning(
        rebuildable: this,
        notifier: notifier,
      );
    }
    notifier.dependents.add(this);
  }

  @internal
  @override
  @nonVirtual
  void internalSetup(
    ProxyRef ref,
    BaseProvider<BaseNotifier<T>, T>? provider,
  ) {
    _watchableRef = WatchableRefImpl(
      container: ref.container,
      rebuildable: this,
    );

    super.internalSetup(ref, provider);
  }

  @override
  @mustCallSuper
  void dispose() {
    _rebuildController.dispose();
    super.dispose();
  }

  /// Schedules a rebuild in the next microtask.
  @override
  @nonVirtual
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

  /// Rebuilds the notifier immediately.
  R rebuildImmediately(LabeledReference debugOrigin);

  @override
  @nonVirtual
  void onDisposeWidget() {}

  @override
  @nonVirtual
  void notifyListenerTarget(BaseNotifier notifier) {}

  @override
  @nonVirtual
  bool get isWidget => false;
}

@internal
class RefDependencyListener<R> {
  final R result;
  final void Function() _cancel;

  RefDependencyListener(this.result, this._cancel);

  void cancel() {
    _cancel();
  }
}

@internal
void printAlreadyWatchedWarning({
  required Rebuildable rebuildable,
  required BaseNotifier notifier,
}) {
  print('''
$_red[Refena] In ${rebuildable.debugLabel}, ${notifier.debugLabel} is watched multiple times! Only watch each provider once in a build method. Tip: Use records to combine multiple fields.$_reset''');
  print('''
$_red[Refena] A non-breaking stacktrace will be printed for easier debugging:$_reset\n${StackTrace.current}''');
}

const _red = '\x1B[31m';
const _reset = '\x1B[0m';
