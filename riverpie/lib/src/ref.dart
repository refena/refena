import 'dart:async';

import 'package:riverpie/src/async_value.dart';
import 'package:riverpie/src/container.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/emittable.dart';
import 'package:riverpie/src/notifier/listener.dart';
import 'package:riverpie/src/notifier/notifier_event.dart';
import 'package:riverpie/src/notifier/rebuildable.dart';
import 'package:riverpie/src/notifier/types/async_notifier.dart';
import 'package:riverpie/src/notifier/types/immutable_notifier.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/types/async_notifier_provider.dart';
import 'package:riverpie/src/provider/types/redux_provider.dart';
import 'package:riverpie/src/provider/watchable.dart';

/// The base ref to read and notify providers.
/// These methods can be called anywhere.
/// Even within dispose methods.
/// The primary difficulty is to get the [Ref] in the first place.
abstract class Ref {
  /// Get the current value of a provider without listening to changes.
  T read<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider);

  /// Get the notifier of a provider.
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider);

  /// Get an [Emittable] of a provider.
  Emittable<N, E> redux<N extends BaseReduxNotifier<T, E>, T, E extends Object>(
    ReduxProvider<N, T, E> provider,
  );

  /// Listen for changes to a provider.
  ///
  /// Do not call this method during build as you
  /// will create a new listener every time.
  ///
  /// You need to dispose the subscription manually.
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
  );

  /// Get the [Future] of an [AsyncNotifierProvider].
  Future<T> future<N extends AsyncNotifier<T>, T>(
    AsyncNotifierProvider<N, T> provider,
  );

  /// Returns the owner of this [Ref].
  /// Usually, this is a notifier or a widget.
  /// Used by [Ref.redux] to log the owner of the event.
  String get debugOwnerLabel;
}

/// The ref available in a [State] with the mixin or in a [ViewProvider].
class WatchableRef extends Ref {
  WatchableRef({
    required RiverpieContainer ref,
    required Rebuildable rebuildable,
  })  : _ref = ref,
        _rebuildable = rebuildable;

  final RiverpieContainer _ref;
  final Rebuildable _rebuildable;

  @override
  T read<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _ref.read<N, T>(provider);
  }

  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    return _ref.notifier<N, T>(provider);
  }

  @override
  Emittable<N, E> redux<N extends BaseReduxNotifier<T, E>, T, E extends Object>(
    ReduxProvider<N, T, E> provider,
  ) {
    return Emittable(
      notifier: _ref.anyNotifier(provider),
      debugOrigin: debugOwnerLabel,
    );
  }

  @override
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
  ) {
    return _ref.stream<N, T>(provider);
  }

  @override
  Future<T> future<N extends AsyncNotifier<T>, T>(
    AsyncNotifierProvider<N, T> provider,
  ) {
    return _ref.future<N, T>(provider);
  }

  /// Get the current value of a provider and listen to changes.
  /// The listener will be disposed automatically when the widget is disposed.
  ///
  /// Optionally, you can pass a [rebuildWhen] function to control when the
  /// widget should rebuild.
  ///
  /// Instead of `ref.watch(provider)`, you can also
  /// use `ref.watch(provider.select((state) => state.attribute))` to
  /// select a part of the state and only rebuild when this part changes.
  ///
  /// Only call [watch] during build.
  R watch<N extends BaseNotifier<T>, T, R>(
    Watchable<N, T, R> watchable, {
    ListenerCallback<T>? listener,
    bool Function(T prev, T next)? rebuildWhen,
  }) {
    final notifier = _ref.anyNotifier(watchable.provider);
    if (notifier is! ImmutableNotifier) {
      // We need to add a listener to the notifier
      // to rebuild the widget when the state changes.
      if (watchable is SelectedWatchable) {
        notifier.addListener(
          _rebuildable,
          ListenerConfig(
            callback: listener,
            rebuildWhen: (prev, next) {
              if (rebuildWhen?.call(prev, next) == false) {
                return false;
              }
              return watchable.getSelectedState(prev) !=
                  watchable.getSelectedState(next);
            },
          ),
        );
      } else {
        notifier.addListener(
          _rebuildable,
          ListenerConfig(
            callback: listener,
            rebuildWhen: rebuildWhen,
          ),
        );
      }
    }

    // ignore: invalid_use_of_protected_member
    return watchable.getSelectedState(notifier.state);
  }

  /// Similar to [watch] but also returns the previous value.
  /// Only works with [AsyncNotifierProvider].
  ChronicleSnapshot<T> watchWithPrev<N extends AsyncNotifier<T>, T>(
    AsyncNotifierProvider<N, T> provider, {
    ListenerCallback<AsyncValue<T>>? listener,
    bool Function(AsyncValue<T> prev, AsyncValue<T> next)? rebuildWhen,
  }) {
    final notifier = _ref.anyNotifier(provider);
    notifier.addListener(
      _rebuildable,
      ListenerConfig(
        callback: listener,
        rebuildWhen: rebuildWhen,
      ),
    );

    // ignore: invalid_use_of_protected_member
    return ChronicleSnapshot(notifier.prev, notifier.state);
  }

  @override
  String get debugOwnerLabel => _rebuildable.debugLabel;
}

/// A [Ref] that proxies all calls to another [Ref].
/// Used to provide a custom [debugOwnerLabel] to [Ref.redux].
class ProxyRef extends Ref {
  ProxyRef(this._ref, this.debugOwnerLabel);

  /// The ref to proxy all calls to.
  final RiverpieContainer _ref;

  /// The owner of this [Ref].
  @override
  final String debugOwnerLabel;

  @override
  T read<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _ref.read<N, T>(provider);
  }

  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    return _ref.notifier<N, T>(provider);
  }

  @override
  Emittable<N, E> redux<N extends BaseReduxNotifier<T, E>, T, E extends Object>(
    ReduxProvider<N, T, E> provider,
  ) {
    return Emittable(
      notifier: _ref.anyNotifier(provider),
      debugOrigin: debugOwnerLabel,
    );
  }

  @override
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
  ) {
    return _ref.stream<N, T>(provider);
  }

  @override
  Future<T> future<N extends AsyncNotifier<T>, T>(
    AsyncNotifierProvider<N, T> provider,
  ) {
    return _ref.future<N, T>(provider);
  }
}

class ChronicleSnapshot<T> {
  /// The state of the notifier before the latest [future] was set.
  /// This is null if [AsyncNotifier.savePrev] is false
  /// or the future has never changed.
  final AsyncValue<T>? prev;

  /// The current state of the notifier.
  final AsyncValue<T> curr;

  ChronicleSnapshot(this.prev, this.curr);
}
