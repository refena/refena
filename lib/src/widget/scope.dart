import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier.dart';
import 'package:riverpie/src/provider/provider.dart';
import 'package:riverpie/src/provider/state.dart';
import 'package:riverpie/src/ref.dart';

/// The [RiverpieScope] holds the state of all providers.
/// Every provider is initialized lazily and only once.
///
/// You can override a provider by passing [overrides] to the constructor.
/// In this case, the state of the provider is initialized right away.
class RiverpieScope extends InheritedWidget implements Ref {
  final _state = <BaseProvider, BaseProviderState>{};

  RiverpieScope({
    super.key,
    List<ProviderOverride> overrides = const [],
    required super.child,
  }) {
    for (final override in overrides) {
      final state = override.state;
      if (state is NotifierProviderState) {
        // ignore: invalid_use_of_protected_member
        state.getNotifier().setRefAndInit(this);
      }
      _state[override.provider] = state;
    }
  }

  @internal
  BaseProviderState getState(BaseProvider provider) {
    BaseProviderState? state = _state[provider];
    if (state == null) {
      state = provider.createState(this);
      _state[provider] = state;
    }
    return state;
  }

  /// Returns the actual value of a [Provider].
  @internal
  T getValue<T>(BaseProvider<T> provider) {
    final state = getState(provider) as BaseProviderState<T>;
    return state.getValue();
  }

  /// Returns the notifier of a [NotifierProvider].
  @internal
  N getNotifier<N extends Notifier<T>, T>(NotifierProvider<N, T> provider) {
    final state = getState(provider) as NotifierProviderState<N, T>;
    return state.getNotifier();
  }

  @override
  bool updateShouldNotify(RiverpieScope oldWidget) {
    return false;
  }

  @override
  N Function<N extends Notifier<T>, T>(NotifierProvider<N, T> provider)
      get notify {
    return getNotifier;
  }

  @override
  T Function<T>(BaseProvider<T> provider) get read {
    return getValue;
  }
}
