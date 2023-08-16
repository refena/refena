import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/riverpie.dart';
// ignore: implementation_imports
import 'package:riverpie/src/notifier/base_notifier.dart';
// ignore: implementation_imports
import 'package:riverpie/src/provider/base_provider.dart';
// ignore: implementation_imports
import 'package:riverpie/src/provider/override.dart';

/// A wrapper widget around [RiverpieContainer].
class RiverpieScope extends InheritedWidget implements RiverpieContainer {
  /// If you are unable to access the [ref] for whatever reason,
  /// there is a pragmatic solution for that.
  /// This is considered bad practice and should only be used as a last resort.
  ///
  /// Usage:
  /// RiverpieScope.defaultRef.read(myProvider);
  static late Ref defaultRef;

  /// Holds all provider states
  final RiverpieContainer _container;

  /// The provided observer (e.g. for logging)
  @override
  RiverpieObserver? get observer => _container.observer;

  /// Creates a [RiverpieScope].
  /// The [overrides] are used to override providers with a different value.
  /// The [initialProviders] are used to initialize providers right away.
  /// Otherwise, the providers are initialized lazily when they are accessed.
  /// The [observer] is used to observe events.
  /// The [child] is the widget tree that is wrapped by the [RiverpieScope].
  RiverpieScope({
    super.key,
    List<ProviderOverride> overrides = const [],
    List<BaseProvider> initialProviders = const [],
    RiverpieObserver? observer,
    required super.child,
  }) : _container = RiverpieContainer(
          overrides: overrides,
          initialProviders: initialProviders,
          observer: observer,
        ) {
    defaultRef = this;
  }

  /// Returns the actual value of a [Provider].
  @override
  // ignore: invalid_use_of_internal_member
  T read<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _container.read(provider);
  }

  /// Returns the notifier of a [NotifierProvider].
  @override
  // ignore: invalid_use_of_internal_member
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    return _container.notifier(provider);
  }

  /// Returns the notifier of a [NotifierProvider].
  /// This method is used internally without
  /// any [NotifyableProvider] constraints.
  @override
  // ignore: invalid_use_of_internal_member
  N anyNotifier<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _container.anyNotifier(provider);
  }

  @override
  // ignore: invalid_use_of_internal_member
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

  @internal
  @override
  bool updateShouldNotify(RiverpieScope oldWidget) {
    return false;
  }
}
