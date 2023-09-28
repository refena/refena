import 'dart:async';

import 'package:riverpie/src/action/dispatcher.dart';
import 'package:riverpie/src/labeled_reference.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/notifier_event.dart';
import 'package:riverpie/src/notifier/types/async_notifier.dart';
import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/types/async_notifier_provider.dart';
import 'package:riverpie/src/provider/types/notifier_provider.dart';
import 'package:riverpie/src/provider/types/redux_provider.dart';
import 'package:riverpie/src/proxy_ref.dart';
import 'package:riverpie/src/ref.dart';

/// The [RiverpieContainer] holds the state of all providers.
/// Every provider state is initialized lazily and only once.
///
/// The [RiverpieContainer] is used as [ref]
/// - within provider builders and
/// - within notifiers.
///
/// You can override a provider by passing [overrides] to the constructor.
/// In this case, the state of the provider is initialized right away.
class RiverpieContainer extends Ref with LabeledReference {
  /// Creates a [RiverpieContainer].
  /// The [overrides] are used to override providers with a different value.
  /// The [initialProviders] are used to initialize providers right away.
  /// Otherwise, the providers are initialized lazily when they are accessed.
  /// The [defaultNotifyStrategy] defines when widgets and providers
  /// are notified to rebuild.
  /// The [observer] is used to observe events.
  RiverpieContainer({
    List<ProviderOverride> overrides = const [],
    List<BaseProvider> initialProviders = const [],
    this.defaultNotifyStrategy = NotifyStrategy.identity,
    this.observer,
  })  : _overrides = _overridesToMap(overrides),
        _overridesList = overrides {
    // Initialize observer
    if (observer != null) {
      observer!.internalSetup(ProxyRef(
        this,
        observer!.debugLabel,
        observer!,
      ));
      observer!.init();
    }

    _overridesFuture = _initOverrides();

    // initialize all specified providers right away
    for (final provider in initialProviders) {
      _getState(provider, ProviderInitCause.initial);
    }
  }

  /// Holds all provider states
  final _state = <BaseProvider, BaseNotifier>{};

  /// The provided observer (e.g. for logging)
  final RiverpieObserver? observer;

  /// The default notify strategy
  final NotifyStrategy defaultNotifyStrategy;

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

    observer?.handleEvent(
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
              'Future override not yet initialized. Call await RiverpieContainer.ensureOverrides() first.');
        }
      }

      notifier = overridden ??
          provider.createState(
            _withProviderLabel(provider),
          );
      notifier.internalSetup(_withNotifierLabel(notifier), provider);
      _state[provider] = notifier;

      observer?.handleEvent(
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
  void dispose<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    final notifier = _state[provider];
    if (notifier != null) {
      // Call dispose on the notifier
      // The state is not removed YET.
      notifier.dispose(); // ignore: invalid_use_of_protected_member

      // Remove the state from the container
      _state.remove(provider);

      observer?.handleEvent(
        ProviderDisposeEvent(
          provider: provider,
          notifier: notifier,
        ),
      );
    }
  }

  @override
  void message(String message) {
    observer?.handleEvent(MessageEvent(message, this));
  }

  @override
  RiverpieContainer get container => this;

  @override
  String get debugOwnerLabel => 'RiverpieContainer';

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

extension on Map<BaseProvider, FutureOr<BaseNotifier> Function(ProxyRef ref)> {
  /// Returns the overridden notifier for the provider.
  FutureOr<N>? createState<N extends BaseNotifier<T>, T>(
      BaseProvider<N, T> provider, ProxyRef ref) {
    return this[provider]?.call(ref) as FutureOr<N>?;
  }
}
