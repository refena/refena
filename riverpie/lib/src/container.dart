import 'dart:async';

import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/emittable.dart';
import 'package:riverpie/src/notifier/notifier_event.dart';
import 'package:riverpie/src/notifier/types/async_notifier.dart';
import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/types/async_notifier_provider.dart';
import 'package:riverpie/src/provider/types/notifier_provider.dart';
import 'package:riverpie/src/provider/types/redux_provider.dart';
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
class RiverpieContainer extends Ref {
  /// Creates a [RiverpieContainer].
  /// The [overrides] are used to override providers with a different value.
  /// The [initialProviders] are used to initialize providers right away.
  /// Otherwise, the providers are initialized lazily when they are accessed.
  /// The [observer] is used to observe events.
  RiverpieContainer({
    List<ProviderOverride> overrides = const [],
    List<BaseProvider> initialProviders = const [],
    this.observer,
  }) : _overrides = _overridesToMap(overrides) {
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

  /// The overrides that are used to create overridden notifiers.
  final Map<BaseProvider, FutureOr<BaseNotifier> Function(Ref ref)>? _overrides;

  /// The future that can be awaited on until all overrides are initialized.
  late final Future<void> _overridesFuture;

  /// Awaiting this future will ensure that all overrides are initialized.
  /// Calling it multiple times is safe.
  Future<void> ensureOverrides() {
    return _overridesFuture;
  }

  Future<void> _initOverrides() async {
    final overrides = _overrides?.entries;
    if (overrides == null) {
      return;
    }

    for (final override in overrides) {
      final provider = override.key;
      if (_state.containsKey(provider)) {
        // Already initialized
        // This may happen when a provider depends on another provider and
        // both are overridden.
        continue;
      }

      final notifierOrFuture = ProviderOverride(
        provider: provider,
        createState: override.value,
      ).createState(_withProviderLabel(provider));

      final BaseNotifier notifier = switch (notifierOrFuture) {
        Future<BaseNotifier> future => await future,
        BaseNotifier notifier => notifier,
      };

      notifier.setup(_withNotifierLabel(notifier), observer);
      _state[provider] = notifier;

      observer?.handleEvent(
        ProviderInitEvent(
          provider: provider,
          notifier: notifier,
          value: notifier.state, // ignore: invalid_use_of_protected_member
          cause: ProviderInitCause.override,
        ),
      );
    }
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
        throw StateError(
            'Future override not initialized. Call await RiverpieContainer.ensureOverrides() first and ensure that the order of the overrides is correct.');
      }

      notifier = overridden ??
          provider.createState(
            _withProviderLabel(provider),
          );
      notifier.setup(_withNotifierLabel(notifier), observer);
      _state[provider] = notifier;

      observer?.handleEvent(
        ProviderInitEvent(
          provider: provider,
          notifier: notifier,
          value: notifier.state, // ignore: invalid_use_of_protected_member
          cause: overridden != null ? ProviderInitCause.override : cause,
        ),
      );
    }
    return notifier;
  }

  /// Returns the actual value of a [Provider].
  @override
  T read<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    // ignore: invalid_use_of_protected_member
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
  Emittable<N, E> redux<N extends BaseReduxNotifier<T, E>, T, E extends Object>(
    ReduxProvider<N, T, E> provider,
  ) {
    return Emittable<N, E>(
      notifier: _getState(provider),
      debugOrigin: debugOwnerLabel,
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
  String get debugOwnerLabel => 'RiverpieContainer';

  RiverpieContainer _withNotifierLabel(BaseNotifier notifier) {
    return _ProxyContainer(
        this, notifier.debugLabel ?? notifier.runtimeType.toString());
  }

  RiverpieContainer _withProviderLabel<N extends BaseNotifier<T>, T>(
      BaseProvider<N, T> provider) {
    return _ProxyContainer(
      this,
      provider.debugLabel ?? N.toString(),
    );
  }
}

/// A container that proxies all calls to another [RiverpieContainer].
/// Used to have a custom [debugOwnerLabel] for [Ref.redux].
class _ProxyContainer implements RiverpieContainer {
  _ProxyContainer(this._container, this.debugOwnerLabel);

  /// The container to proxy all calls to.
  final RiverpieContainer _container;

  /// The owner of this [Ref].
  @override
  final String debugOwnerLabel;

  @override
  late final Future<void> _overridesFuture;

  @override
  Future<void> ensureOverrides() {
    return _container.ensureOverrides();
  }

  @override
  Future<void> _initOverrides() => throw UnimplementedError();

  @override
  T read<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _container.read<N, T>(provider);
  }

  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    return _container.notifier<N, T>(provider);
  }

  @override
  N anyNotifier<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _container.anyNotifier<N, T>(provider);
  }

  @override
  Emittable<N, E> redux<N extends BaseReduxNotifier<T, E>, T, E extends Object>(
    ReduxProvider<N, T, E> provider,
  ) {
    return Emittable(
      notifier: _container._getState(provider),
      debugOrigin: debugOwnerLabel,
    );
  }

  @override
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
  ) {
    return _container.stream<N, T>(provider);
  }

  @override
  Future<T> future<N extends AsyncNotifier<T>, T>(
    AsyncNotifierProvider<N, T> provider,
  ) {
    return _container.future<N, T>(provider);
  }

  @override
  N _getState<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider,
      [ProviderInitCause cause = ProviderInitCause.access]) {
    throw UnimplementedError();
  }

  @override
  Map<BaseProvider<BaseNotifier, dynamic>, BaseNotifier Function(Ref ref)>?
      get _overrides => throw UnimplementedError();

  @override
  Map<BaseProvider<BaseNotifier, dynamic>, BaseNotifier> get _state =>
      throw UnimplementedError();

  @override
  RiverpieContainer _withNotifierLabel(BaseNotifier notifier) {
    throw UnimplementedError();
  }

  @override
  RiverpieContainer _withProviderLabel<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
  ) {
    throw UnimplementedError();
  }

  @override
  RiverpieObserver? get observer => throw UnimplementedError();
}

Map<BaseProvider, FutureOr<BaseNotifier> Function(Ref ref)>? _overridesToMap(
    List<ProviderOverride> overrides) {
  return overrides.isEmpty
      ? null
      : Map.fromEntries(
          overrides.map(
            (override) => MapEntry(override.provider, override.createState),
          ),
        );
}

extension on Map<BaseProvider, FutureOr<BaseNotifier> Function(Ref ref)> {
  /// Returns the overridden notifier for the provider.
  FutureOr<N>? createState<N extends BaseNotifier<T>, T>(
      BaseProvider<N, T> provider, Ref ref) {
    return this[provider]?.call(ref) as FutureOr<N>?;
  }
}
