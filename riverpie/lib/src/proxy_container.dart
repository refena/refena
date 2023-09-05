import 'package:riverpie/src/action/dispatcher.dart';
import 'package:riverpie/src/container.dart';
import 'package:riverpie/src/labeled_reference.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/notifier_event.dart';
import 'package:riverpie/src/notifier/types/async_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/types/async_notifier_provider.dart';
import 'package:riverpie/src/provider/types/redux_provider.dart';

/// A container that proxies all calls to another [RiverpieContainer].
/// Used to have a custom [debugOwnerLabel] for [Ref.redux].
class ProxyContainer implements RiverpieContainer {
  ProxyContainer(this._container, this.debugOwnerLabel, this._debugOriginRef);

  /// The container to proxy all calls to.
  final RiverpieContainer _container;

  /// The owner of this [Ref].
  @override
  final String debugOwnerLabel;

  final LabeledReference _debugOriginRef;

  @override
  Future<void> ensureOverrides() {
    return _container.ensureOverrides();
  }

  @override
  T read<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _container.read<N, T>(provider);
  }

  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    return _container.notifier<N, T>(provider);
  }

  @override
  N anyNotifier<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _container.anyNotifier<N, T>(provider);
  }

  @override
  Dispatcher<N, T> redux<N extends BaseReduxNotifier<T>, T, E extends Object>(
    ReduxProvider<N, T> provider,
  ) {
    return Dispatcher(
      notifier: _container.anyNotifier(provider),
      debugOrigin: debugOwnerLabel,
      debugOriginRef: _debugOriginRef,
    );
  }

  @override
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
  ) {
    return _container.stream<N, T>(provider);
  }

  @override
  Future<T> future<N extends AsyncNotifier<T>, T>(
    AsyncNotifierProvider<N, T> provider,
  ) {
    return _container.future<N, T>(provider);
  }

  @override
  void dispose<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    _container.dispose<N, T>(provider);
  }

  @override
  void message(String message) {
    _container.message(message);
  }

  @override
  NotifyStrategy get defaultNotifyStrategy => _container.defaultNotifyStrategy;

  @override
  RiverpieObserver? get observer => _container.observer;

  @override
  String get debugLabel => _debugOriginRef.debugLabel;

  @override
  bool compareIdentity(LabeledReference other) =>
      _container.compareIdentity(other);
}
