import 'package:riverpie/src/container.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/emittable.dart';
import 'package:riverpie/src/notifier/notifier_event.dart';
import 'package:riverpie/src/notifier/types/async_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/types/async_notifier_provider.dart';
import 'package:riverpie/src/provider/types/redux_provider.dart';

/// A container that proxies all calls to another [RiverpieContainer].
/// Used to have a custom [debugOwnerLabel] for [Ref.redux].
class ProxyContainer implements RiverpieContainer {
  ProxyContainer(this._container, this.debugOwnerLabel);

  /// The container to proxy all calls to.
  final RiverpieContainer _container;

  /// The owner of this [Ref].
  @override
  final String debugOwnerLabel;

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
  Emittable<N, E> redux<N extends BaseReduxNotifier<T, E>, T, E extends Object>(
    ReduxProvider<N, T, E> provider,
  ) {
    return Emittable(
      notifier: _container.anyNotifier(provider),
      debugOrigin: debugOwnerLabel,
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
  RiverpieObserver? get observer => _container.observer;
}
