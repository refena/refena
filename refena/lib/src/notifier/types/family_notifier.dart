part of '../base_notifier.dart';

typedef ChildFamilyBuilder<T, F, P extends BaseProvider<BaseNotifier<T>, T>> = P
    Function(
  F param,
);

/// The family notifier manages a map of notifiers, one for each parameter.
/// They are created lazily when the parameter is accessed for the first time.
///
/// [T] is the type of **one** element of the family.
/// [F] is the type of the family parameter.
/// [P] is the type of the child provider.
final class FamilyNotifier<T, F, P extends BaseProvider<BaseNotifier<T>, T>>
    extends BaseSyncNotifier<Map<F, T>>
    with RebuildableNotifier<Map<F, T>, void> {
  FamilyNotifier(
    this._familyBuilder, {
    String Function(T state)? describeState,
  }) : _describeState = describeState;

  final ChildFamilyBuilder<T, F, P> _familyBuilder;

  @override
  void Function(WatchableRef ref) get _builder => throw UnimplementedError();

  final Map<F, P> _providers = {};
  final String Function(T state)? _describeState;

  @override
  Map<F, T> init() => {};

  @override
  void postInit() {
    _rebuildController.stream.listen((event) {
      // rebuild notifier state
      _setStateAsRebuild(
        this,
        {
          for (final entry in _providers.entries)
            entry.key: _watchableRef.read(
              entry.value as BaseWatchable<BaseNotifier<T>, T, T>,
            ),
        },
        event,
        null,
      );
    });
  }

  bool isParamInitialized(F param) {
    return state.containsKey(param);
  }

  void initParam(F param) {
    // create new temporary provider
    final provider = _familyBuilder(param);
    _providers[param] = provider;
    _initDependencies(provider);

    _state = {
      ...state,
      param: _watchableRef.watch(
        provider as BaseWatchable<BaseNotifier<T>, T, T>,
      ),
    };
  }

  void disposeParam(F param, LabeledReference? debugOrigin) {
    final provider = _providers.remove(param);
    if (provider == null) {
      return;
    }

    _clearDependencies(provider);
    _container!.internalDispose(provider, debugOrigin ?? this);
    state.remove(param);
  }

  @override
  void dispose() {
    super.dispose();
    // This will cause the temporary providers to be disposed
    // after this notifier is disposed.
    // The reason we do this is because we want to show the correct
    // event chain in the tracing.
    dependents.addAll(_providers.values.map((provider) {
      return _container!.anyNotifier<BaseNotifier<T>, T>(provider);
    }));
    _providers.clear();
    state.clear();
  }

  void _initDependencies(BaseProvider<BaseNotifier<T>, T> tempProvider) {
    final tempNotifier = _container!.anyNotifier(tempProvider);
    // so this notifier (the family notifier) won't get disposed
    tempNotifier._fakeDependents = true;
    dependencies.add(tempNotifier);
    tempNotifier.dependents.add(this);
  }

  void _clearDependencies(BaseProvider<BaseNotifier<T>, T> tempProvider) {
    final tempNotifier = _container!.anyNotifier(tempProvider);
    dependencies.remove(tempNotifier);
    tempNotifier.dependents.clear();
  }

  @override
  String describeState(Map<F, T> state) {
    if (_describeState != null) {
      return _describeMapState(state, _describeState!);
    } else {
      return _describeMapState(state, (value) => value.toString());
    }
  }

  @override
  void rebuildImmediately(LabeledReference debugOrigin) {
    for (final provider in _providers.values) {
      _container!.rebuild(provider as RebuildableProvider, debugOrigin);
    }
  }
}

@internal
extension FamilyNotifierExt<T, F, P extends BaseProvider<BaseNotifier<T>, T>>
    on FamilyNotifier<T, F, P> {
  List<BaseProvider<BaseNotifier<T>, T>> getTempProviders() {
    return _providers.values.toList();
  }

  Map<F, P> getProviderMap() {
    return _providers;
  }
}
