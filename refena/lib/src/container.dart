import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:refena/src/action/dispatcher.dart';
import 'package:refena/src/action/redux_action.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/notifier/notifier_event.dart';
import 'package:refena/src/notifier/types/async_notifier.dart';
import 'package:refena/src/observer/event.dart';
import 'package:refena/src/observer/observer.dart';
import 'package:refena/src/observer/tracing_observer.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/types/async_notifier_provider.dart';
import 'package:refena/src/provider/types/notifier_provider.dart';
import 'package:refena/src/provider/types/redux_provider.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';
import 'package:refena/src/reference.dart';

enum PlatformHint {
  /// The platform is Android.
  android,

  /// The platform is iOS.
  iOS,

  /// The platform is windows
  windows,

  /// The platform is macOS
  macOS,

  /// The platform is linux
  linux,

  /// The platform is web.
  web,

  /// Unknown platform
  unknown,
}

/// The [RefenaContainer] holds the state of all providers.
/// Every provider state is initialized lazily and only once.
///
/// The [RefenaContainer] is used as [ref]
/// - within provider builders and
/// - within notifiers.
///
/// You can override a provider by passing [overrides] to the constructor.
/// In this case, the state of the provider is initialized right away.
class RefenaContainer implements Ref, LabeledReference {
  /// Creates a [RefenaContainer].
  ///
  /// The [platformHint] gives the container a hint about the platform.
  /// This abstraction is used by the inspector that does not depend on
  /// Flutter.
  /// The [overrides] are used to override providers with a different value.
  /// The [initialProviders] are used to initialize providers right away.
  /// Otherwise, the providers are initialized lazily when they are accessed.
  /// The [defaultNotifyStrategy] defines when widgets and providers
  /// are notified to rebuild.
  /// The [observers] is used to observe events.
  /// The [initImmediately] defines whether the container should be initialized
  /// right away.
  RefenaContainer({
    this.platformHint = PlatformHint.unknown,
    List<ProviderOverride> overrides = const [],
    List<BaseProvider> initialProviders = const [],
    this.defaultNotifyStrategy = NotifyStrategy.equality,
    List<RefenaObserver> observers = const [],
    bool initImmediately = true,
  })  : _overrides = _overridesToMap(overrides),
        _overridesList = overrides,
        _initialProviders = initialProviders,
        observer = _observerListToSingleObserver(observers) {
    if (initImmediately) {
      init();
    }
  }

  /// Initializes the container.
  void init() {
    // Initialize observer
    final observer = this.observer;
    if (observer != null) {
      observer.internalSetup(ProxyRef(
        this,
        observer.debugLabel,
        observer,
      ));
    }

    // Initialize overrides
    _overridesFuture = _initOverrides();

    // Initialize all specified providers right away
    for (final provider in _initialProviders) {
      _getState(provider, ProviderInitCause.initial);
    }
  }

  final List<BaseProvider> _initialProviders;

  /// The platform hint.
  /// This is used by the inspector_client to determine the host IP.
  final PlatformHint platformHint;

  /// Holds all provider states
  final _state = <BaseProvider, BaseNotifier>{};

  /// The provided observer (e.g. for logging)
  final RefenaObserver? observer;

  /// The default notify strategy
  final NotifyStrategy defaultNotifyStrategy;

  bool _disposed = false;

  /// Whether the container has been disposed.
  bool get disposed => _disposed;

  /// The overrides that are used to create overridden notifiers.
  final Map<BaseProvider, FutureOr<BaseNotifier> Function(ProxyRef ref)>?
      _overrides;

  /// The ordered overrides.
  final List<ProviderOverride> _overridesList;

  /// During initialization: current override index.
  int _overrideIndex = 0;

  /// The future that can be awaited on until all overrides are initialized.
  late final Future<void> _overridesFuture;

  /// Awaiting this future will ensure that all overrides are initialized.
  /// Calling it multiple times is safe.
  Future<void> ensureOverrides() {
    return _overridesFuture;
  }

  Future<void> _initOverrides() async {
    if (_overridesList.isEmpty) {
      return;
    }

    for (int i = 0; i < _overridesList.length; i++) {
      _overrideIndex = i;
      await _override(_overridesList[i]);
    }
  }

  /// Initializes the state of a single provider with a predefined state.
  /// By default, it skips already initialized providers.
  /// If [force] is true, it will override the state of already initialized
  /// providers.
  Future<void> _override(
    ProviderOverride override, {
    bool force = false,
  }) async {
    final provider = override.provider;
    if (!force && _state.containsKey(provider)) {
      // Already initialized
      // This may happen when a provider depends on another provider and
      // both are overridden.
      return;
    }

    final notifierOrFuture = override.createState(_withProviderLabel(provider));

    final BaseNotifier notifier = switch (notifierOrFuture) {
      Future<BaseNotifier> future => await future,
      BaseNotifier notifier => notifier,
    };

    notifier.internalSetup(_withNotifierLabel(notifier), provider);
    _state[provider] = notifier;

    observer?.internalHandleEvent(
      ProviderInitEvent(
        provider: provider,
        notifier: notifier,
        value: notifier.state,
        cause: ProviderInitCause.override,
      ),
    );

    notifier.postInit();
  }

  /// Returns the state of the provider.
  ///
  /// If the provider is accessed the first time,
  /// it will be initialized.
  N _getState<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider, [
    ProviderInitCause cause = ProviderInitCause.access,
  ]) {
    N? notifier = _state[provider] as N?;
    if (notifier == null) {
      final overridden = _overrides?.createState(
        provider,
        _withProviderLabel(provider),
      );

      if (overridden is Future) {
        // Check index for better error messages
        final overrideIndex = _overridesList.indexWhere(
          (override) => override.provider == provider,
        );
        if (overrideIndex > _overrideIndex) {
          throw ArgumentError(
              '[${_overridesList[_overrideIndex].provider.debugLabel}] depends on [${provider.debugLabel}] which is overridden later. Reorder future overrides.');
        } else {
          throw StateError(
              'Future override not yet initialized. Call await RefenaContainer.ensureOverrides() first.');
        }
      }

      notifier = overridden ??
          provider.createState(
            _withProviderLabel(provider),
          );
      notifier.internalSetup(_withNotifierLabel(notifier), provider);
      _state[provider] = notifier;

      observer?.internalHandleEvent(
        ProviderInitEvent(
          provider: provider,
          notifier: notifier,
          value: notifier.state,
          cause: overridden != null ? ProviderInitCause.override : cause,
        ),
      );

      notifier.postInit();
    }

    return notifier;
  }

  /// Overrides a provider with a new value.
  /// This allows for overrides happening after the container was created.
  FutureOr<void> set(ProviderOverride override) {
    return _override(override, force: true);
  }

  /// Returns the actual value of a [Provider].
  @override
  T read<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _getState(provider).state;
  }

  /// Returns the notifier of a [NotifierProvider].
  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    return _getState(provider as BaseProvider<N, T>);
  }

  /// Returns the notifier of a [NotifierProvider].
  /// This method can be used to avoid the constraint of [NotifyableProvider].
  /// Useful for testing.
  N anyNotifier<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _getState(provider);
  }

  @override
  Dispatcher<N, T> redux<N extends BaseReduxNotifier<T>, T, E extends Object>(
    ReduxProvider<N, T> provider,
  ) {
    return Dispatcher<N, T>(
      notifier: _getState(provider),
      debugOrigin: debugOwnerLabel,
      debugOriginRef: this,
    );
  }

  @override
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
  ) {
    return _getState(provider).getStream();
  }

  @override
  Future<T> future<N extends AsyncNotifier<T>, T>(
    AsyncNotifierProvider<N, T> provider,
  ) {
    // ignore: invalid_use_of_protected_member
    return _getState(provider).future;
  }

  @override
  void dispose<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
  ) {
    internalDispose(provider, this);
  }

  @override
  void message(String message) {
    observer?.internalHandleEvent(MessageEvent(message, this));
  }

  @override
  RefenaContainer get container => this;

  @internal
  void internalDispose<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
    LabeledReference debugOrigin,
  ) {
    final notifier = _state[provider];
    if (notifier == null) {
      return;
    }

    final queue = Queue<BaseNotifier>();
    final originMap = <BaseNotifier, ProviderDisposeEvent?>{};
    final observer = this.observer;
    queue.add(notifier);
    do {
      // Call dispose on the notifier
      // The state is not removed YET.
      final current = queue.removeFirst();

      final dependents = current.internalDispose();

      // Remove the state from the container
      // The state is removed AFTER the remove call.
      final provider = current.provider!;
      _state.remove(provider);

      if (observer != null) {
        final event = ProviderDisposeEvent(
          debugOrigin: originMap[current] ?? debugOrigin,
          provider: provider,
        );
        observer.internalHandleEvent(event);

        for (final dependent in dependents) {
          if (!originMap.containsKey(dependent)) {
            originMap[dependent] = event;
            queue.add(dependent);
          }
        }
      } else {
        for (final dependent in dependents) {
          if (!originMap.containsKey(dependent)) {
            originMap[dependent] = null;
            queue.add(dependent);
          }
        }
      }
    } while (queue.isNotEmpty);
  }

  List<BaseNotifier> getActiveNotifiers() {
    return [
      ..._state.values.where((n) => n is! GlobalRedux && n is! TracingNotifier)
    ];
  }

  /// Removes disposed listeners from all notifiers.
  /// This happens regularly, but you can call it manually if you want to
  /// to visualize the current state.
  void cleanupListeners() {
    for (final notifier in _state.values) {
      notifier.cleanupListeners();
    }
  }

  /// Disposes the container itself.
  /// It will also dispose all providers.
  /// After calling this method, the container should not be used anymore.
  void disposeContainer() {
    for (final provider in [..._state.keys]) {
      internalDispose(provider, this);
    }

    observer?.dispose();
    _disposed = true;
  }

  @override
  String get debugOwnerLabel => 'RefenaContainer';

  @override
  String get debugLabel => debugOwnerLabel;

  ProxyRef _withNotifierLabel(BaseNotifier notifier) {
    return ProxyRef(
      this,
      notifier.debugLabel,
      notifier,
    );
  }

  ProxyRef _withProviderLabel<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
  ) {
    return ProxyRef(
      this,
      provider.debugLabel,
      provider,
    );
  }
}

Map<BaseProvider, FutureOr<BaseNotifier> Function(ProxyRef ref)>?
    _overridesToMap(
  List<ProviderOverride> overrides,
) {
  return overrides.isEmpty
      ? null
      : Map.fromEntries(
          overrides.map(
            (override) => MapEntry(override.provider, override.createState),
          ),
        );
}

/// Automatically converts a list of observers to a single observer by
/// wrapping them in a [RefenaMultiObserver].
RefenaObserver? _observerListToSingleObserver(List<RefenaObserver> observers) {
  if (observers.isEmpty) {
    return null;
  } else if (observers.length == 1) {
    return observers.first;
  } else {
    return RefenaMultiObserver(observers: observers);
  }
}

extension on Map<BaseProvider, FutureOr<BaseNotifier> Function(ProxyRef ref)> {
  /// Returns the overridden notifier for the provider.
  FutureOr<N>? createState<N extends BaseNotifier<T>, T>(
      BaseProvider<N, T> provider, ProxyRef ref) {
    return this[provider]?.call(ref) as FutureOr<N>?;
  }
}
