// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/riverpie.dart';

// ignore: implementation_imports
import 'package:riverpie/src/notifier/base_notifier.dart';

// ignore: implementation_imports
import 'package:riverpie/src/provider/base_provider.dart';

/// A wrapper widget around [RiverpieContainer].
class RiverpieScope extends InheritedWidget implements RiverpieContainer {
  /// Creates a [RiverpieScope].
  /// The [overrides] are used to override providers with a different value.
  /// The [initialProviders] are used to initialize providers right away.
  /// Otherwise, the providers are initialized lazily when they are accessed.
  /// The [defaultNotifyStrategy] defines when widgets and providers
  /// are notified to rebuild.
  /// The [observer] is used to observe events.
  /// The [child] is the widget tree that is wrapped by the [RiverpieScope].
  RiverpieScope({
    super.key,
    List<ProviderOverride> overrides = const [],
    List<BaseProvider> initialProviders = const [],
    NotifyStrategy defaultNotifyStrategy = NotifyStrategy.identity,
    RiverpieObserver? observer,
    required super.child,
  }) : _container = RiverpieContainer(
          overrides: overrides,
          initialProviders: initialProviders,
          defaultNotifyStrategy: defaultNotifyStrategy,
          observer: observer,
        ) {
    defaultRef = this;
  }

  /// If you are unable to access the [ref] for whatever reason,
  /// there is a pragmatic solution for that.
  /// This is considered bad practice and should only be used as a last resort.
  ///
  /// Usage:
  /// RiverpieScope.defaultRef.read(myProvider);
  static late Ref defaultRef;

  /// Holds all provider states
  final RiverpieContainer _container;

  /// The default notify strategy
  @override
  NotifyStrategy get defaultNotifyStrategy => _container.defaultNotifyStrategy;

  /// The provided observer (e.g. for logging)
  @override
  RiverpieObserver? get observer => _container.observer;

  /// Awaiting this future will ensure that all overrides are initialized.
  /// Calling it multiple times is safe.
  @override
  Future<void> ensureOverrides() {
    return _container.ensureOverrides();
  }

  /// Overrides a provider with a new value.
  /// This allows for overrides happening after the container was created.
  @override
  FutureOr<void> set(ProviderOverride override) {
    return _container.set(override);
  }

  /// Returns the actual value of a [Provider].
  @override
  T read<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _container.read(provider);
  }

  /// Returns the notifier of a [NotifierProvider].
  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    return _container.notifier(provider);
  }

  /// Returns the notifier of a [NotifierProvider].
  /// This method is used internally without
  /// any [NotifyableProvider] constraints.
  @override
  N anyNotifier<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _container.anyNotifier(provider);
  }

  @override
  Dispatcher<N, T> redux<N extends BaseReduxNotifier<T>, T, E extends Object>(
    ReduxProvider<N, T> provider,
  ) {
    return Dispatcher(
      notifier: _container.anyNotifier(provider),
      debugOrigin: debugOwnerLabel,
      debugOriginRef: this,
    );
  }

  @override
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
  ) {
    return _container.stream(provider);
  }

  @override
  Future<T> future<N extends AsyncNotifier<T>, T>(
    AsyncNotifierProvider<N, T> provider,
  ) {
    return _container.future(provider);
  }

  @override
  void dispose<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    _container.dispose(provider);
  }

  @override
  void message(String message) {
    _container.message(message);
  }

  @override
  RiverpieContainer get container => _container;

  @override
  List<BaseNotifier> getActiveNotifiers() => _container.getActiveNotifiers();

  @override
  void cleanupListeners() => _container.cleanupListeners();

  @internal
  @override
  bool updateShouldNotify(RiverpieScope oldWidget) {
    return false;
  }

  @override
  String get debugOwnerLabel => 'RiverpieScope';

  @override
  String get debugLabel => debugOwnerLabel;

  @override
  bool compareIdentity(LabeledReference other) =>
      _container.compareIdentity(other);
}
