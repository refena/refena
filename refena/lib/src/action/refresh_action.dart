import 'package:refena/src/action/redux_action.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/base_notifier.dart';

/// An action that refreshes the state of a [ReduxNotifier].
/// The state must be an [AsyncValue] with the data type [T].
///
/// This action does the boilerplate process of
/// - setting the state to [AsyncValue.loading]
/// - catching errors and setting the state to [AsyncValue.withError]
/// - setting the state to [AsyncValue.withData] with the result of [refresh]
///
/// Example:
/// class MyRefreshAction extends RefreshAction<MyNotifier, int> {
///   @override
///   Future<int> refresh() async {
///     await Future.delayed(Duration(seconds: 1));
///     return 42;
///   }
/// }
abstract class RefreshAction<N extends ReduxNotifier<AsyncValue<T>>, T>
    extends AsyncReduxAction<N, AsyncValue<T>> {
  /// Implement the refresh logic here.
  Future<T> refresh();

  @override
  Future<AsyncValue<T>> reduce() async {
    final prev = state.data;
    dispatch(RefreshSetLoadingAction<N, T>(prev));
    try {
      return AsyncValue<T>.data(await refresh());
    } catch (error, stackTrace) {
      dispatch(RefreshSetErrorAction<N, T>(
        error: error,
        stackTrace: stackTrace,
        previousData: prev,
      ));
      rethrow;
    }
  }
}

/// Sets the state of a [ReduxNotifier] to [AsyncValue.loading].
class RefreshSetLoadingAction<N extends ReduxNotifier<AsyncValue<T>>, T>
    extends ReduxAction<N, AsyncValue<T>> {
  final T? previousData;

  RefreshSetLoadingAction(this.previousData);

  @override
  AsyncValue<T> reduce() {
    return AsyncValue<T>.loading(previousData);
  }

  @override
  bool operator ==(Object other) {
    return other is RefreshSetLoadingAction &&
        other.previousData == previousData;
  }

  @override
  int get hashCode => 0;

  @override
  String get debugLabel => 'RefreshSetLoadingAction';
}

/// Sets the state of a [ReduxNotifier] to [AsyncValue.withError].
class RefreshSetErrorAction<N extends ReduxNotifier<AsyncValue<T>>, T>
    extends ReduxAction<N, AsyncValue<T>> {
  final Object error;
  final StackTrace stackTrace;
  final T? previousData;

  RefreshSetErrorAction({
    required this.error,
    required this.stackTrace,
    this.previousData,
  });

  @override
  AsyncValue<T> reduce() {
    return AsyncValue<T>.error(error, stackTrace, previousData);
  }

  @override
  bool operator ==(Object other) {
    return other is RefreshSetErrorAction &&
        other.error == error &&
        other.previousData == previousData;
  }

  @override
  int get hashCode => error.hashCode;

  @override
  String get debugLabel => 'RefreshSetErrorAction';
}
