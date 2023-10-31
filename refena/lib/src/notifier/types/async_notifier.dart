import 'package:meta/meta.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';

/// An [AsyncNotifier] is a notifier that holds the state of an [AsyncSnapshot].
/// It is used for business logic that depends on asynchronous operations.
abstract class AsyncNotifier<T> extends BaseAsyncNotifier<T> {
  AsyncNotifier({super.debugLabel});

  late Ref _ref;

  @protected
  Ref get ref => _ref;

  /// A helper method to set the state of the notifier.
  ///
  /// Usage:
  /// setState((_) async {
  ///   final response = await ref.read(apiProvider).fetchDashboard();
  ///   return response.data;
  /// });
  ///
  /// With snapshot:
  /// setState((snapshot) async {
  ///   return (snapshot.curr ?? 0) + 1;
  /// });
  @protected
  Future<T> setState(
    Future<T> Function(NotifierSnapshot<T> snapshot) fn,
  ) async {
    future = fn(NotifierSnapshot(state.data, state, future));
    return await future;
  }

  @internal
  @override
  void internalSetup(
    ProxyRef ref,
    BaseProvider? provider,
  ) {
    _ref = ref;
    super.internalSetup(ref, provider);
  }

  /// Returns a debug version of the [notifier] where
  /// you can set the state directly.
  static AsyncNotifierTester<N, T> test<N extends BaseAsyncNotifier<T>, T>({
    required N notifier,
    AsyncValue<T>? initialState,
  }) {
    return AsyncNotifierTester(
      notifier: notifier,
      initialState: initialState,
    );
  }
}

/// A snapshot of the [AsyncNotifier].
class NotifierSnapshot<T> {
  /// The current value. It is null, if the future is not completed.
  /// Shorthand for [currSnapshot.data].
  final T? curr;

  /// The current snapshot.
  final AsyncValue<T>? currSnapshot;

  /// The current future.
  final Future<T> currFuture;

  NotifierSnapshot(this.curr, this.currSnapshot, this.currFuture);
}
