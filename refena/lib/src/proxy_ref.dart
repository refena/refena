import 'package:meta/meta.dart';
import 'package:refena/src/action/dispatcher.dart';
import 'package:refena/src/container.dart';
import 'package:refena/src/labeled_reference.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/notifier/notifier_event.dart';
import 'package:refena/src/notifier/types/async_notifier.dart';
import 'package:refena/src/observer/event.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/types/async_notifier_provider.dart';
import 'package:refena/src/provider/types/redux_provider.dart';
import 'package:refena/src/ref.dart';

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
  T read<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    if (_onAccessNotifier == null) {
      return _ref.read<N, T>(provider);
    }

    final notifier = _ref.anyNotifier<N, T>(provider);
    _onAccessNotifier!(notifier);
    return notifier.state;
  }

  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    final notifier = _ref.notifier<N, T>(provider);
    _onAccessNotifier?.call(notifier);
    return notifier;
  }

  @override
  Dispatcher<N, T> redux<N extends BaseReduxNotifier<T>, T, E extends Object>(
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
    BaseProvider<N, T> provider,
  ) {
    if (_onAccessNotifier == null) {
      return _ref.stream<N, T>(provider);
    }

    final notifier = _ref.anyNotifier<N, T>(provider);
    _onAccessNotifier!(notifier);
    return notifier.getStream();
  }

  @override
  Future<T> future<N extends AsyncNotifier<T>, T>(
    AsyncNotifierProvider<N, T> provider,
  ) {
    if (_onAccessNotifier == null) {
      return _ref.future<N, T>(provider);
    }

    final notifier = _ref.anyNotifier(provider);
    _onAccessNotifier!(notifier);
    return notifier.future; // ignore: invalid_use_of_protected_member
  }

  @override
  void dispose<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    _ref.dispose<N, T>(provider);
  }

  @override
  void message(String message) {
    _ref.observer?.internalHandleEvent(
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
