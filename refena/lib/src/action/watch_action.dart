part of 'redux_action.dart';

/// TLDR:
/// This action reruns the [reduce] method whenever a watched provider changes.
///
/// This action is handy if you want to add additional properties to the state
/// but you don't want to write an extra [ViewProvider] / listener for it.
/// It reruns the [reduce] method and dispatches a [WatchUpdateAction]
/// whenever a watched provider changes.
///
/// Usually, this action is dispatched in the [initialAction]
/// of a [ReduxNotifier].
///
/// Override [before] to implement some logic before the [reduce] method.
/// It will run only once, when the [WatchAction] is first dispatched.
///
/// All [WatchAction]s are automatically cancelled when the [ReduxNotifier]
/// is disposed, but you can also cancel them manually by saving the result
/// of the [dispatchTakeResult] method in a variable
/// and calling [WatchActionSubscription.cancel] on it.
///
/// Similarly to [GlobalAction], this action also has access to the [Ref] so
/// be careful to not produce any unwanted side effects.
///
/// Example:
/// class MyNotifier extends ReduxNotifier<MyState> {
///   @override
///   MyState init() => MyState();
///
///   @override
///   get initialAction => MyWatchAction();
/// }
///
/// class MyWatchAction extends WatchAction<MyNotifier, MyState> {
///   @override
///   MyState reduce() {
///     final counter = ref.watch(anotherProvider);
///
///     return state.copyWith(
///       counter: counter,
///     );
///   }
/// }
///
/// {@category Redux}
abstract class WatchAction<N extends BaseReduxNotifier<T>, T>
    extends BaseReduxActionWithResult<N, T, WatchActionSubscription>
    implements Rebuildable {
  /// The dependencies of this [WatchAction].
  final _actionDependencies = <BaseNotifier>{};

  /// The controller to schedule rebuilds.
  final _rebuildController = BatchedStreamController<void>();

  /// Whether the [WatchAction] is disposed (cancelled).
  bool _disposed = false;

  /// Access the [Ref].
  /// This is a special ref that can watch other providers.
  late final WatchableRef ref = WatchableRefImpl(
    container: _originalRef!.container,
    rebuildable: this,
  );

  /// The method that returns the new state.
  /// Whenever a watched provider changes, this method is called again.
  T reduce();

  /// Override this to have some logic before and after the [reduce] method.
  /// Specifically, this method is called after [before] and before [after]:
  /// [before] -> [wrapReduce] -> [after]
  T wrapReduce() => reduce();

  @override
  @internal
  @nonVirtual
  (T, WatchActionSubscription) internalWrapReduce() {
    final notifierDependencies = {..._notifier.dependencies};
    _rebuildController.stream.listen((event) {
      _reduceWithDependencyCheck(
        notifierDependencies: notifierDependencies,
        dispatchNewAction: true,
      );
    });
    final subscription = WatchActionSubscription(this);
    notifier.registerWatchAction(subscription);
    return (
      _reduceWithDependencyCheck(
        notifierDependencies: notifierDependencies,
        dispatchNewAction: false,
      ),
      subscription
    );
  }

  T _reduceWithDependencyCheck({
    required Set<BaseNotifier> notifierDependencies,
    required bool dispatchNewAction,
  }) {
    if (notifier.disposed) {
      dispose();
      return state;
    }

    // rebuild
    final oldDeps = {..._actionDependencies};
    _actionDependencies.clear();

    final newState = (ref as WatchableRefImpl).trackNotifier(
      onAccess: (notifier) {
        final added = _actionDependencies.add(notifier);
        if (!added) {
          printAlreadyWatchedWarning(
            rebuildable: this,
            notifier: notifier,
          );
        }
      },
      run: () {
        if (dispatchNewAction) {
          return notifier.dispatch(
            WatchUpdateAction._(wrapReduce()),
            debugOrigin: debugLabel,
          );
        } else {
          return wrapReduce();
        }
      },
    );

    final removedDeps = oldDeps.difference(_actionDependencies);
    for (final removedDependency in removedDeps) {
      // remove listener to avoid future rebuilds
      removedDependency.removeListener(this);
    }

    return newState;
  }

  @override
  @internal
  void rebuild(ChangeEvent? changeEvent, RebuildEvent? rebuildEvent) {
    _rebuildController.schedule(null);
  }

  @override
  @nonVirtual
  bool get isWidget => false;

  @override
  @nonVirtual
  bool get disposed => _disposed;

  @override
  void onDisposeWidget() {}

  @override
  void notifyListenerTarget(BaseNotifier notifier) {}

  @mustCallSuper
  void dispose() {
    _disposed = true;
    _rebuildController.dispose();
  }

  /// Subclasses should not override this method.
  /// It is used internally by [WatchableRef.watch].
  @override
  @nonVirtual
  bool operator ==(Object other) => super == other;

  @override
  @nonVirtual
  int get hashCode => super.hashCode;
}

/// A handle to cancel a [WatchAction].
/// Usually this is not needed as the [WatchAction] is automatically
/// cancelled when the [ReduxNotifier] is disposed.
class WatchActionSubscription {
  final WatchAction _action;

  WatchActionSubscription(this._action);

  /// Cancel the [WatchAction].
  /// It no longer rebuild the state.
  void cancel() {
    _action.dispose();
  }

  /// Whether the [WatchAction] is disposed (cancelled).
  bool get disposed => _action.disposed;
}

/// A simple action that updates the state.
final class WatchUpdateAction<N extends BaseReduxNotifier<T>, T>
    extends ReduxAction<N, T> {
  final T newState;

  WatchUpdateAction._(this.newState);

  @override
  bool get trackOrigin => false;

  @override
  T reduce() {
    return newState;
  }

  @override
  String get debugLabel => 'WatchUpdateAction';
}
