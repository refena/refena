// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:riverpie/src/listener.dart';
import 'package:riverpie/src/provider/provider.dart';
import 'package:riverpie/src/provider/state.dart';
import 'package:riverpie/src/widget/scope.dart';
import 'package:riverpie/src/notifier.dart';
import 'package:riverpie/src/ref.dart';

mixin Riverpie<W extends StatefulWidget> on State<W> {
  /// Access this ref inside your [State].
  late final ref = WatchableRef(
    watch: _watch,
    listen: _listen,
    read: _read,
    notify: _notify,
  );

  T _watch<T>(BaseProvider<T> provider) {
    return _internalListen(provider: provider, listener: null);
  }

  T _listen<T>(BaseProvider<T> provider, ListenerCallback<T> listener) {
    return _internalListen(provider: provider, listener: listener);
  }

  T _internalListen<T>({
    required BaseProvider<T> provider,
    required ListenerCallback<T>? listener,
  }) {
    final state = _getScope(context).getState(provider);
    if (state is ProviderState<T>) {
      // A normal provider is immutable, so we can return the value directly.
      return state.getValue();
    } else if (state is NotifierProviderState<Notifier<T>, T>) {
      // A notifier provider is mutable, so we also need to add a listener.
      final notifier = state.getNotifier();
      notifier.addListener(this, listener);
      return notifier.state;
    }

    throw Exception(
        'Only [Provider] and [NotifierProvider] are supported, got: ${provider.runtimeType}');
  }

  T _read<T>(BaseProvider<T> provider) {
    return _getScope(context).getValue(provider);
  }

  N _notify<N extends Notifier<T>, T>(NotifierProvider<N, T> provider) {
    return _getScope(context).getNotifier(provider);
  }
}

RiverpieScope _getScope(BuildContext context) {
  final scope = context.dependOnInheritedWidgetOfExactType<RiverpieScope>();
  if (scope == null) {
    throw Exception('Wrap your app with RiverpieScope');
  }
  return scope;
}
