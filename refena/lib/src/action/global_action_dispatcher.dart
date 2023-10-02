import 'package:refena/src/action/redux_action.dart';
import 'package:refena/src/ref.dart';

extension GlobalActionExtension on Ref {
  /// Dispatches a global action.
  /// Returns the result of the action.
  R dispatch<R>(GlobalActionWithResult<R> action) {
    return _dispatch(this, action);
  }

  /// Dispatches an async global action.
  /// Returns the result of the action.
  Future<R> dispatchAsync<R>(AsyncGlobalActionWithResult<R> action) {
    return _dispatchAsync(this, action);
  }
}

class GlobalActionDispatcher {
  final Ref _ref;

  GlobalActionDispatcher(this._ref);

  /// Dispatches a global action (sync or async).
  /// Returns the result of the action.
  ///
  /// If the action is async, null is returned.
  /// You don't need to worry, this is type-safe.
  R dispatch<R>(GlobalActionWithResult<R> action) {
    return _dispatch(_ref, action);
  }

  /// Dispatches an async global action.
  /// Returns the result of the action.
  Future<R> dispatchAsync<R>(AsyncGlobalActionWithResult<R> action) {
    return _dispatchAsync(_ref, action);
  }
}

/// Dispatches a sync or an async global action.
/// Returns the result of the action.
R _dispatch<R>(Ref ref, GlobalActionWithResult<R> action) {
  return ref.redux(globalReduxProvider).dispatchTakeResult(action);
}

/// Dispatches an async global action.
/// Returns the result of the action.
Future<R> _dispatchAsync<R>(Ref ref, AsyncGlobalActionWithResult<R> action) {
  return ref.redux(globalReduxProvider).dispatchAsyncTakeResult(action);
}
