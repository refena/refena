import 'package:meta/meta.dart';
import 'package:riverpie/src/action/dispatcher.dart';
import 'package:riverpie/src/container.dart';
import 'package:riverpie/src/labeled_reference.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/notifier_event.dart';
import 'package:riverpie/src/notifier/types/async_notifier.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/types/async_notifier_provider.dart';
import 'package:riverpie/src/provider/types/redux_provider.dart';
import 'package:riverpie/src/ref.dart';

/// A ref that proxies all calls to another [Ref].
/// Used to have a custom [debugOwnerLabel] for [Ref.redux].
@internal
class ProxyRef implements Ref {
  ProxyRef(this._ref, this.debugOwnerLabel, this._debugOriginRef);

  /// The container to proxy all calls to.
  final Ref _ref;

  /// The owner of this [Ref].
  @override
  final String debugOwnerLabel;

  final LabeledReference _debugOriginRef;

  @override
  T read<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _ref.read<N, T>(provider);
  }

  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    return _ref.notifier<N, T>(provider);
  }

  @override
  Dispatcher<N, T> redux<N extends BaseReduxNotifier<T>, T, E extends Object>(
    ReduxProvider<N, T> provider,
  ) {
    return Dispatcher(
      notifier: _ref.notifier(provider),
      debugOrigin: debugOwnerLabel,
      debugOriginRef: _debugOriginRef,
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

  @override
  void dispose<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    _ref.dispose<N, T>(provider);
  }

  @override
  void message(String message) {
    _ref.message(message);
  }

  @override
  RiverpieContainer get container => _ref.container;
}
