import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/listener.dart';
import 'package:riverpie/src/notifier/types/async_notifier.dart';
import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/types/async_notifier_provider.dart';
import 'package:riverpie/src/ref.dart';

/// The [RiverpieScope] holds the state of all providers.
/// Every provider state is initialized lazily and only once.
///
/// The [RiverpieScope] is used as [ref]
/// - within provider build callbacks and
/// - within notifiers.
///
/// You can override a provider by passing [overrides] to the constructor.
/// In this case, the state of the provider is initialized right away.
class RiverpieScope extends InheritedWidget implements Ref {
  /// If you are unable to access the [ref] for whatever reason,
  /// there is a pragmatic solution for that.
  /// This is considered bad practice and should only be used as a last resort.
  ///
  /// Usage:
  /// RiverpieScope.defaultRef.read(myProvider);
  static late Ref defaultRef;

  /// Holds all provider states
  final _state = <BaseProvider, BaseNotifier>{};

  /// The provided observer (e.g. for logging)
  final RiverpieObserver? observer;

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
    this.observer,
    required super.child,
  }) {
    defaultRef = this;

    for (final override in overrides) {
      final state = override.state;
      state.setup(this, observer);
      _state[override.provider] = state;

      observer?.handleEvent(
        ProviderInitEvent(
          provider: override.provider,
          notifier: state,
          value: state.state, // ignore: invalid_use_of_protected_member
          cause: ProviderInitCause.override,
        ),
      );
    }

    // initialize all specified providers right away
    for (final provider in initialProviders) {
      _getState(provider, ProviderInitCause.initial);
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
    N? state = _state[provider] as N?;
    if (state == null) {
      state = provider.createState(this, observer);
      _state[provider] = state;

      observer?.handleEvent(
        ProviderInitEvent(
          provider: provider,
          notifier: state,
          value: state.state, // ignore: invalid_use_of_protected_member
          cause: cause,
        ),
      );
    }
    return state;
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
  /// This method is used internally without
  /// any [NotifyableProvider] constraints.
  @internal
  N anyNotifier<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _getState(provider);
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

  @internal
  @override
  bool updateShouldNotify(RiverpieScope oldWidget) {
    return false;
  }
}
