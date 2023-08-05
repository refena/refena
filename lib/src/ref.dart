import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpie/src/listener.dart';
import 'package:riverpie/src/notifier.dart';
import 'package:riverpie/src/provider/provider.dart';

/// The base ref to read and notify providers.
/// These methods can be called anywhere.
/// Even within dispose methods.
/// The primary difficulty is to get the [Ref] in the first place.
abstract class Ref {
  /// Get the current value of a provider without listening to changes.
  T read<T>(BaseProvider<T> provider);

  /// Get the notifier of a provider.
  N notifier<N extends BaseNotifier<T>, T>(NotifierProvider<N, T> provider);

  /// Listen for changes to a provider.
  ///
  /// Do not call this method during build as you
  /// will create a new listener every time.
  ///
  /// You need to dispose the subscription manually.
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    NotifierProvider<N, T> provider,
  );
}

/// The ref to watch providers (in addition to read, notify and stream).
class WatchableRef extends Ref {
  final Ref _root;
  final State _state;

  @override
  T read<T>(BaseProvider<T> provider) {
    return _root.read<T>(provider);
  }

  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifierProvider<N, T> provider) {
    return _root.notifier<N, T>(provider);
  }

  @override
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    NotifierProvider<N, T> provider,
  ) {
    return _root.stream<N, T>(provider);
  }

  /// Get the current value of a provider and listen to changes.
  /// The listener will be disposed automatically when the widget is disposed.
  /// Only call [watch] during build.
  T watch<T>(
    BaseProvider<T> provider, {
    ListenerCallback<T>? listener,
    bool Function(T prev, T next)? rebuildWhen,
  }) {
    if (provider is Provider<T>) {
      // A normal provider is immutable, so we can return the value directly.
      return _root.read(provider);
    } else if (provider is NotifierProvider<BaseNotifier<T>, T>) {
      // A notifier provider is mutable, so we also need to add a listener.
      final notifier = _root.notifier(provider);
      notifier.addListener(
        _state,
        ListenerConfig(
          callback: listener,
          selector: rebuildWhen,
        ),
      );

      // ignore: invalid_use_of_protected_member
      return notifier.state;
    }

    throw Exception(
        'Only [Provider] and [NotifierProvider] are supported, got: ${provider.runtimeType}');
  }

  WatchableRef({
    required Ref root,
    required State state,
  })  : _root = root,
        _state = state;
}
