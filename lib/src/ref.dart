import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpie/riverpie.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/listener.dart';
import 'package:riverpie/src/notifier/rebuildable.dart';
import 'package:riverpie/src/provider/base_provider.dart';

/// The base ref to read and notify providers.
/// These methods can be called anywhere.
/// Even within dispose methods.
/// The primary difficulty is to get the [Ref] in the first place.
abstract class Ref {
  /// Get the current value of a provider without listening to changes.
  T read<T>(BaseProvider<T> provider);

  /// Get the notifier of a provider.
  N notifier<N extends BaseNotifier<T>, T>(BaseNotifierProvider<N, T> provider);

  /// Listen for changes to a provider.
  ///
  /// Do not call this method during build as you
  /// will create a new listener every time.
  ///
  /// You need to dispose the subscription manually.
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    BaseNotifierProvider<N, T> provider,
  );

  /// Get the [Future] of an [AwaitableProvider].
  Future<T> future<T>(AwaitableProvider<T> provider);
}

/// The ref available in a [State] with the mixin or in a [ViewProvider].
class WatchableRef extends Ref {
  final Ref _ref;
  final Rebuildable _rebuildable;

  @override
  T read<T>(BaseProvider<T> provider) {
    return _ref.read<T>(provider);
  }

  @override
  N notifier<N extends BaseNotifier<T>, T>(
      BaseNotifierProvider<N, T> provider) {
    return _ref.notifier<N, T>(provider);
  }

  @override
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    BaseNotifierProvider<N, T> provider,
  ) {
    return _ref.stream<N, T>(provider);
  }

  @override
  Future<T> future<T>(AwaitableProvider<T> provider) {
    return _ref.future<T>(provider);
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
      return _ref.read(provider);
    } else if (provider is BaseNotifierProvider<BaseNotifier<T>, T>) {
      // A notifier provider is mutable, so we also need to add a listener.
      final notifier = _ref.notifier(provider);
      notifier.addListener(
        _rebuildable,
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

  /// Similar to [watch] but also returns the previous value.
  /// Only works with [AsyncNotifierProvider].
  ChronicleSnapshot<T> watchWithPrev<N extends AsyncNotifier<T>, T>(
    AsyncNotifierProvider<N, T> provider, {
    ListenerCallback<AsyncSnapshot<T>>? listener,
    bool Function(AsyncSnapshot<T> prev, AsyncSnapshot<T> next)? rebuildWhen,
  }) {
    final notifier = _ref.notifier(provider);
    notifier.addListener(
      _rebuildable,
      ListenerConfig(
        callback: listener,
        selector: rebuildWhen,
      ),
    );

    // ignore: invalid_use_of_protected_member
    return ChronicleSnapshot(notifier.prev, notifier.state);
  }

  WatchableRef._(this._ref, this._rebuildable);

  /// Create a [WatchableRef] from an [Element].
  factory WatchableRef.fromElement({
    required Ref ref,
    required Element element,
  }) {
    return WatchableRef._(
      ref,
      ElementRebuildable(element),
    );
  }

  /// Create a [WatchableRef] from a [Rebuildable].
  factory WatchableRef.fromRebuildable({
    required Ref ref,
    required Rebuildable rebuildable,
  }) {
    return WatchableRef._(
      ref,
      rebuildable,
    );
  }
}

class ChronicleSnapshot<T> {
  /// The state of the notifier before the latest [future] was set.
  /// This is null if [AsyncNotifier.savePrev] is false
  /// or the future has never changed.
  final AsyncSnapshot<T>? prev;

  /// The current state of the notifier.
  final AsyncSnapshot<T> curr;

  ChronicleSnapshot(this.prev, this.curr);
}
