import 'package:meta/meta.dart';
import 'package:refena/src/accessor.dart';
import 'package:refena/src/action/dispatcher.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/container.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/notifier/notifier_event.dart';
import 'package:refena/src/observer/event.dart';
import 'package:refena/src/observer/observer.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/provider_accessor.dart';
import 'package:refena/src/provider/types/redux_provider.dart';
import 'package:refena/src/provider/watchable.dart';
import 'package:refena/src/ref.dart';
import 'package:refena/src/reference.dart';

/// A ref that proxies all calls to another [Ref].
/// Used to have a custom [debugOwnerLabel] for [Ref.redux].
@internal
class ProxyRef implements Ref {
  ProxyRef(this._ref, this.debugOwnerLabel, this._debugOriginRef);

  /// The container to proxy all calls to.
  final RefenaContainer _ref;

  /// The owner of this [Ref].
  @override
  final String debugOwnerLabel;

  final LabeledReference _debugOriginRef;

  @override
  R read<N extends BaseNotifier<T>, T, R>(BaseWatchable<N, T, R> watchable) {
    if (_onAccessNotifier == null) {
      return _ref.read<N, T, R>(watchable);
    }

    final notifier = _ref.anyNotifier<N, T>(watchable.provider);
    _onAccessNotifier!(notifier);
    return _ref.read<N, T, R>(watchable);
  }

  @override
  StateAccessor<R> accessor<R>(
    BaseWatchable<BaseNotifier, dynamic, R> provider,
  ) {
    final notifier = _ref.anyNotifier(provider.provider);
    _onAccessNotifier?.call(notifier);
    return StateAccessor<R>(
      ref: this,
      provider: provider,
    );
  }

  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    final notifier = _ref.notifier<N, T>(provider);
    _onAccessNotifier?.call(notifier);
    return notifier;
  }

  @override
  Dispatcher<N, T> redux<N extends ReduxNotifier<T>, T>(
    ReduxProvider<N, T> provider,
  ) {
    final notifier = _ref.anyNotifier(provider);
    _onAccessNotifier?.call(notifier);
    return Dispatcher(
      notifier: notifier,
      debugOrigin: debugOwnerLabel,
      debugOriginRef: _debugOriginRef,
    );
  }

  @override
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    ProviderAccessor<BaseProvider<N, T>, N, T> provider,
  ) {
    if (_onAccessNotifier == null) {
      return _ref.stream<N, T>(provider);
    }

    final notifier = _ref.anyNotifier(provider.provider);
    _onAccessNotifier!(notifier);
    if (notifier is N) {
      return notifier.getStream();
    }

    // The given provider was a family provider.
    // Access the child provider and return its future.
    final actualProvider = provider.getActualProvider(notifier);
    return _ref.anyNotifier(actualProvider).getStream();
  }

  @override
  Future<T> future<N extends GetFutureNotifier<T>, T>(
    ProviderAccessor<BaseProvider<N, AsyncValue<T>>, N, AsyncValue<T>> provider,
  ) {
    if (_onAccessNotifier == null) {
      return _ref.future<N, T>(provider);
    }

    final notifier = _ref.anyNotifier(provider.provider);
    _onAccessNotifier!(notifier);
    if (notifier is N) {
      return notifier.future;
    }

    // The given provider was a family provider.
    // Access the child provider and return its future.
    final actualProvider = provider.getActualProvider(notifier);
    return _ref.anyNotifier(actualProvider).future;
  }

  @override
  R rebuild<N extends RebuildableNotifier<T, R>, T, R>(
    RebuildableProvider<N, T, R> provider,
  ) {
    return _ref.rebuild(provider, _debugOriginRef);
  }

  @override
  void dispose<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    _ref.internalDispose<N, T>(provider, _debugOriginRef);
  }

  @override
  void disposeFamilyParam<N extends FamilyNotifier<dynamic, P, dynamic>, P>(
    BaseProvider<N, dynamic> provider,
    P param,
  ) {
    _ref.disposeFamilyParam<N, P>(provider, param);
  }

  @override
  void message(String message) {
    _ref.observer?.dispatchEvent(
      MessageEvent(message, _debugOriginRef),
    );
  }

  @override
  RefenaContainer get container => _ref;

  /// This function is always called when a [BaseNotifier] is accessed.
  /// Used to determine the dependency graph.
  void Function(BaseNotifier)? _onAccessNotifier;

  /// Runs [run] and calls [onAccess] for every [BaseNotifier]
  R trackNotifier<R>({
    required void Function(BaseNotifier) onAccess,
    required R Function() run,
  }) {
    _onAccessNotifier = onAccess;
    final result = run();
    _onAccessNotifier = null;
    return result;
  }

  /// The async version of [trackNotifier].
  Future<R> trackNotifierAsync<R>({
    required void Function(BaseNotifier) onAccess,
    required Future<R> Function() run,
  }) async {
    _onAccessNotifier = onAccess;
    final result = await run();
    _onAccessNotifier = null;
    return result;
  }
}
