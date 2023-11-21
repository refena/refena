part of '../base_notifier.dart';

typedef ChildFamilyBuilder<T, P> = BaseProvider<BaseNotifier<T>, T> Function(
  P param,
);

/// The family notifier manages a map of notifiers, one for each parameter.
/// They are created lazily when the parameter is accessed for the first time.
final class FamilyNotifier<T, P> extends BaseSyncNotifier<Map<P, T>>
    with RebuildableNotifier {
  FamilyNotifier(
    this._builder, {
    String Function(T state)? describeState,
    super.debugLabel,
  }) : _describeState = describeState;

  final ChildFamilyBuilder<T, P> _builder;
  final Map<P, BaseProvider<BaseNotifier<T>, T>> _providers = {};
  final String Function(T state)? _describeState;

  @override
  Map<P, T> init() => {};

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
      );
    });
  }

  bool isParamInitialized(P param) {
    return state.containsKey(param);
  }

  void initParam(P param) {
    // create new temporary provider
    final provider = _builder(param);
    _providers[param] = provider;
    _initDependencies(provider);

    _state = {
      ...state,
      param: _watchableRef.watch(
        provider as BaseWatchable<BaseNotifier<T>, T, T>,
      ),
    };
  }

  void disposeParam(P param, LabeledReference? debugOrigin) {
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
    for (final provider in _providers.values) {
      _clearDependencies(provider);
      _container!.internalDispose(provider, this);
    }
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

  @visibleForTesting
  List<BaseProvider<BaseNotifier<T>, T>> getTempProviders() {
    return _providers.values.toList();
  }

  @override
  String describeState(Map<P, T> state) {
    if (_describeState != null) {
      return _describeMapState(state, _describeState!);
    } else {
      return _describeMapState(state, (value) => value.toString());
    }
  }
}
