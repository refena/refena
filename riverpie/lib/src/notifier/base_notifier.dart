import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/src/async_value.dart';
import 'package:riverpie/src/container.dart';
import 'package:riverpie/src/notifier/listener.dart';
import 'package:riverpie/src/notifier/notifier_event.dart';
import 'package:riverpie/src/notifier/rebuildable.dart';
import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/types/notifier_provider.dart';

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

  BaseNotifier({required this.debugLabel});

  /// Gets the current state.
  @protected
  T get state => _state;

  /// Sets the state and notify listeners
  @protected
  set state(T value) {
    _setState(value, null);
  }

  /// Sets the state and notify listeners (the actual implementation).
  // We need to extract this method to make [ReduxNotifier] work.
  void _setState(T value, Object? event) {
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
          event: event,
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
  void setup(RiverpieContainer container, RiverpieObserver? observer);

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
  void setup(RiverpieContainer container, RiverpieObserver? observer) {
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
  void setup(RiverpieContainer container, RiverpieObserver? observer) {
    _listeners = NotifierListeners<AsyncValue<T>>(this, observer);
    _observer = observer;

    // do not set future directly, as the setter may be overridden
    _setFutureAndListen(init());

    _initialized = true;
  }
}

/// A notifier where the state can be updated by emitting events.
/// Events are emitted by calling [emit].
/// They are handled by the notifier with [reduce].
///
/// You do not have access to [ref] in this notifier, so you need to pass
/// the required dependencies via constructor.
@internal
abstract class BaseReduxNotifier<T, E extends Object>
    extends BaseSyncNotifier<T> {
  BaseReduxNotifier({String? debugLabel}) : super(debugLabel: debugLabel);

  /// A map of overrides for the reducers.
  Map<Object, Reducer<T, E>?>? _overrides;

  /// Emits an event to update the state.
  void emit(E event) {
    emitAsync(event);
  }

  /// Emits an event to update the state.
  /// This method is async and can be used to await the new state.
  Future<void> emitAsync(E event) async {
    _observer?.handleEvent(EventEmittedEvent(notifier: this, event: event));

    if (_overrides != null) {
      // Handle overrides
      final key = event is Enum ? event : event.runtimeType;
      final override = _overrides![event is Enum ? event : event.runtimeType];
      if (override != null) {
        // Use the override reducer
        final newState = override(state, event);
        _setState(newState, event);
        return;
      } else if (_overrides!.containsKey(key)) {
        // If the override is null (but the key exist),
        // we do not update the state.
        return;
      }
    }

    final newState = reduce(event);
    if (newState is Future<T>) {
      // If the reducer returns a Future, wait for it to complete
      try {
        _setState(await newState, event);
      } catch (e) {
        rethrow;
      }
    } else {
      // If the reducer returns a plain value, update the state directly
      _setState(newState, event);
    }
  }

  /// Returns the new state after applying the event.
  @protected
  FutureOr<T> reduce(E event);

  /// Overrides the reducer for the given event type.
  void _setOverrides(Map<Object, Reducer<T, E>?> overrides) {
    assert(
      overrides.keys.every((k) => k is Type || (k is Enum && k is E)),
      'The keys of the overrides map must be either a Type or a valid Enum. Invalid: ${overrides.keys.whereNot((k) => k is Type || (k is Enum && k is E)).toList()}',
    );
    _overrides = overrides;
  }

  @override
  @internal
  set state(T value) {
    throw UnsupportedError('Not allowed to set state directly');
  }
}

typedef Reducer<T, E extends Object> = T Function(T state, E event);

extension ReduxNotifierOverrideExt<N extends BaseReduxNotifier<T, E>, T,
    E extends Object> on NotifierProvider<N, T> {
  /// Overrides the reducer with the given [overrides].
  ///
  /// Usage:
  /// final ref = RiverpieContainer(
  ///   overrides: [
  ///     notifierProvider.overrideWithReducer(
  ///       overrides: {
  ///         MyEvent: (state, event) => state + 1,
  ///         MyAnotherEvent: null, // empty reducer
  ///         MyEnum.value: null, // enum event
  ///         ...
  ///       },
  ///     ),
  ///   ],
  /// );
  ProviderOverride<N, T> overrideWithReducer({
    N Function()? notifier,
    required Map<Object, Reducer<T, E>?> overrides,
  }) {
    return ProviderOverride<N, T>(
      provider: this,
      createState: (ref) {
        return (notifier?.call() ?? createState(ref)).._setOverrides(overrides);
      },
    );
  }
}
