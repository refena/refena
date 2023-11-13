part of 'redux_action.dart';

/// The global redux provider.
///
/// {@category Redux}
final globalReduxProvider = ReduxProvider<GlobalRedux, void>((_) {
  return GlobalRedux();
}, debugVisibleInGraph: false);

/// The corresponding global redux notifier.
final class GlobalRedux extends ReduxNotifier<void> {
  GlobalRedux();

  @override
  void init() {}
}

mixin GlobalActions<N extends BaseReduxNotifier<T>, T, R>
    on BaseReduxAction<N, T, R> {
  /// Access the global dispatcher.
  late final global = GlobalActionDispatcher(_ref);
}

/// A synchronous global action without a result.
///
/// {@category Redux}
abstract class GlobalAction extends GlobalActionWithResult<void> {}

/// An asynchronous global action without a result.
///
/// {@category Redux}
abstract class AsyncGlobalAction extends AsyncGlobalActionWithResult<void> {}

/// A synchronous global action with a result.
///
/// {@category Redux}
abstract class GlobalActionWithResult<R>
    extends BaseReduxActionWithResult<GlobalRedux, void, R> {
  /// Access the [Ref].
  Ref get ref => _ref;

  /// The method that returns the result.
  R reduce();

  /// Override this to have some logic before and after the [reduce] method.
  /// Specifically, this method is called after [before] and before [after]:
  /// [before] -> [wrapReduce] -> [after]
  R wrapReduce() => reduce();

  @override
  @internal
  @nonVirtual
  (void, R) internalWrapReduce() {
    return (null, wrapReduce());
  }
}

/// An asynchronous global action with a result.
///
/// {@category Redux}
abstract class AsyncGlobalActionWithResult<R>
    extends BaseAsyncReduxActionWithResult<GlobalRedux, void, R> {
  /// Access the [Ref].
  Ref get ref => _ref;

  /// The method that returns the result.
  Future<R> reduce();

  /// Override this to have some logic before and after the [reduce] method.
  /// Specifically, this method is called after [before] and before [after]:
  /// [before] -> [wrapReduce] -> [after]
  Future<R> wrapReduce() => reduce();

  @override
  @internal
  @nonVirtual
  Future<(void, R)> internalWrapReduce() async {
    return (null, await wrapReduce());
  }
}
