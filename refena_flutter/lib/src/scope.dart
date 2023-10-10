// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:refena/refena.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/base_notifier.dart';

// ignore: implementation_imports
import 'package:refena/src/provider/base_provider.dart';

/// A wrapper widget around [RefenaContainer].
class RefenaScope extends InheritedWidget implements RefenaContainer {
  /// Creates a [RefenaScope].
  /// The [overrides] are used to override providers with a different value.
  /// The [initialProviders] are used to initialize providers right away.
  /// Otherwise, the providers are initialized lazily when they are accessed.
  /// The [defaultNotifyStrategy] defines when widgets and providers
  /// are notified to rebuild.
  /// The [observers] are used to observe events.
  /// The [child] is the widget tree that is wrapped by the [RefenaScope].
  RefenaScope({
    super.key,
    PlatformHint? platformHint,
    List<ProviderOverride> overrides = const [],
    List<BaseProvider> initialProviders = const [],
    NotifyStrategy defaultNotifyStrategy = NotifyStrategy.identity,
    List<RefenaObserver> observers = const [],
    bool defaultRef = true,
    required super.child,
  }) : _container = RefenaContainer(
          platformHint: platformHint ?? _getPlatformHint(),
          overrides: overrides,
          initialProviders: initialProviders,
          defaultNotifyStrategy: defaultNotifyStrategy,
          observers: observers,
        ) {
    if (defaultRef) {
      RefenaScope.defaultRef = this;
    }
  }

  /// If you are unable to access the [ref] for whatever reason,
  /// there is a pragmatic solution for that.
  /// This is considered bad practice and should only be used as a last resort.
  ///
  /// Usage:
  /// RefenaScope.defaultRef.read(myProvider);
  static late Ref defaultRef;

  /// Holds all provider states
  final RefenaContainer _container;

  /// The platform hint.
  @override
  PlatformHint get platformHint => _container.platformHint;

  /// The default notify strategy
  @override
  NotifyStrategy get defaultNotifyStrategy => _container.defaultNotifyStrategy;

  /// The provided observer (e.g. for logging)
  @override
  RefenaObserver? get observer => _container.observer;

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
  RefenaContainer get container => _container;

  @override
  void internalDispose<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
    LabeledReference debugOrigin,
  ) {
    _container.internalDispose(provider, debugOrigin);
  }

  @override
  List<BaseNotifier> getActiveNotifiers() => _container.getActiveNotifiers();

  @override
  void cleanupListeners() => _container.cleanupListeners();

  @internal
  @override
  bool updateShouldNotify(RefenaScope oldWidget) {
    return false;
  }

  @override
  String get debugOwnerLabel => 'RefenaScope';

  @override
  String get debugLabel => debugOwnerLabel;
}

PlatformHint _getPlatformHint() {
  if (kIsWeb) {
    return PlatformHint.web;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => PlatformHint.android,
    TargetPlatform.iOS => PlatformHint.iOS,
    TargetPlatform.windows => PlatformHint.windows,
    TargetPlatform.macOS => PlatformHint.macOS,
    TargetPlatform.linux => PlatformHint.linux,
    _ => PlatformHint.unknown,
  };
}
