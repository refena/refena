// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:riverpie/src/listener.dart';
import 'package:riverpie/src/provider/provider.dart';
import 'package:riverpie/src/widget/scope.dart';
import 'package:riverpie/src/notifier.dart';
import 'package:riverpie/src/ref.dart';

mixin Riverpie<W extends StatefulWidget> on State<W> {
  /// Access this ref inside your [State].
  late final ref = WatchableRef(
    watch: _watch,
    listen: _listen,
    read: _read,
    notifier: _notifier,
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
    final ref = _getScope(context);
    if (provider is Provider<T>) {
      // A normal provider is immutable, so we can return the value directly.
      return ref.read(provider);
    } else if (provider is NotifierProvider<BaseNotifier<T>, T>) {
      // A notifier provider is mutable, so we also need to add a listener.
      final notifier = ref.notifier(provider);
      notifier.addListener(this, listener);
      return notifier.state;
    }

    throw Exception(
        'Only [Provider] and [NotifierProvider] are supported, got: ${provider.runtimeType}');
  }

  T _read<T>(BaseProvider<T> provider) {
    return _getScope(context).read(provider);
  }

  N _notifier<N extends BaseNotifier<T>, T>(NotifierProvider<N, T> provider) {
    return _getScope(context).notifier(provider);
  }
}

/// Returns the nearest [RiverpieScope].
RiverpieScope _getScope(BuildContext context) {
  final scope = context.dependOnInheritedWidgetOfExactType<RiverpieScope>();
  if (scope == null) {
    throw Exception('Wrap your app with RiverpieScope');
  }
  return scope;
}
