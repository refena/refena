part of '../base_notifier.dart';

final class ViewProviderNotifier<T> extends BaseSyncNotifier<T>
    implements Rebuildable {
  ViewProviderNotifier(
    this._builder, {
    String Function(T state)? describeState,
    super.debugLabel,
  }) : _describeState = describeState;

  late final WatchableRef _watchableRef;
  final T Function(WatchableRef) _builder;
  final String Function(T state)? _describeState;
  final _rebuildController = BatchedStreamController<AbstractChangeEvent>();

  @override
  T init() {
    _rebuildController.stream.listen((event) {
      // rebuild notifier state
      _setStateAsRebuild(
        this,
        _build(),
        event,
      );
    });
    return _build();
  }

  T _build() {
    final oldDependencies = {...dependencies};
    dependencies.clear();

    final nextState = (_watchableRef as WatchableRefImpl).trackNotifier(
      onAccess: (notifier) {
        final added = dependencies.add(notifier);
        if (!added) {
          printAlreadyWatchedWarning(
            rebuildable: this,
            notifier: notifier,
          );
        }
        notifier.dependents.add(this);
      },
      run: () => _builder(_watchableRef),
    );

    final removedDependencies = oldDependencies.difference(dependencies);
    for (final removedDependency in removedDependencies) {
      // remove from dependency graph
      removedDependency.dependents.remove(this);

      // remove listener to avoid future rebuilds
      removedDependency._listeners.removeListener(this);
    }

    return nextState;
  }

  @internal
  @override
  void internalSetup(
    ProxyRef ref,
    BaseProvider<BaseNotifier<T>, T>? provider,
  ) {
    _watchableRef = WatchableRefImpl(
      container: ref.container,
      rebuildable: this,
    );

    super.internalSetup(ref, provider);
  }

  @override
  void rebuild(ChangeEvent? changeEvent, RebuildEvent? rebuildEvent) {
    assert(
      changeEvent == null || rebuildEvent == null,
      'Cannot have both changeEvent and rebuildEvent',
    );

    if (changeEvent != null) {
      _rebuildController.schedule(changeEvent);
    } else if (rebuildEvent != null) {
      _rebuildController.schedule(rebuildEvent);
    } else {
      _rebuildController.schedule(null);
    }
  }

  @override
  @nonVirtual
  void dispose() {
    _rebuildController.dispose();
  }

  @override
  String describeState(T state) {
    if (_describeState == null) {
      return super.describeState(state);
    }
    return _describeState!(state);
  }

  @override
  void onDisposeWidget() {}

  @override
  void notifyListenerTarget(BaseNotifier notifier) {}

  @override
  bool get isWidget => false;
}
