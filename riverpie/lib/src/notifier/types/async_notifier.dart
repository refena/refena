import 'package:meta/meta.dart';
import 'package:riverpie/src/async_value.dart';
import 'package:riverpie/src/container.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/ref.dart';

/// An [AsyncNotifier] is a notifier that holds the state of an [AsyncSnapshot].
/// It is used for business logic that depends on asynchronous operations.
abstract class AsyncNotifier<T> extends BaseAsyncNotifier<T> {
  AsyncNotifier({super.debugLabel});

  late Ref _ref;

  @protected
  Ref get ref => _ref;

  AsyncValue<T>? _prev;

  /// The state of this notifier before the latest [future] was set.
  AsyncValue<T>? get prev => _prev;

  /// Whether the previous state should be saved.
  /// Override this, if you don't want to save the previous state.
  bool get savePrev => true;

  @override
  @protected
  set future(Future<T> value) {
    if (savePrev) {
      _prev = state;
    }
    super.future = value;
  }

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
  void setup(RiverpieContainer container, RiverpieObserver? observer) {
    _ref = container;
    super.setup(container, observer);
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
