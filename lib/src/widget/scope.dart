import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/src/listener.dart';
import 'package:riverpie/src/notifier.dart';
import 'package:riverpie/src/provider/provider.dart';
import 'package:riverpie/src/provider/state.dart';
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
  final _state = <BaseProvider, BaseProviderState>{};

  RiverpieScope({
    super.key,
    List<ProviderOverride> overrides = const [],
    required super.child,
  }) {
    defaultRef = this;

    for (final override in overrides) {
      final state = override.state;
      if (state is NotifierProviderState) {
        // ignore: invalid_use_of_protected_member
        state.getNotifier().preInit(this);
      }
      _state[override.provider] = state;
    }
  }

  /// Returns the state of the provider.
  ///
  /// If the provider is accessed the first time,
  /// it will be initialized.
  BaseProviderState _getState(BaseProvider provider) {
    BaseProviderState? state = _state[provider];
    if (state == null) {
      state = provider.createState(this);
      _state[provider] = state;
    }
    return state;
  }

  /// Returns the actual value of a [Provider].
  @override
  T read<T>(BaseProvider<T> provider) {
    final state = _getState(provider) as BaseProviderState<T>;
    return state.getValue();
  }

  /// Returns the notifier of a [NotifierProvider].
  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifierProvider<N, T> provider) {
    final state = _getState(provider) as NotifierProviderState<N, T>;
    return state.getNotifier();
  }

  @override
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    NotifierProvider<N, T> provider,
  ) {
    final state = _getState(provider) as NotifierProviderState<N, T>;
    return state.getNotifier().getStream();
  }

  @internal
  @override
  bool updateShouldNotify(RiverpieScope oldWidget) {
    return false;
  }
}
