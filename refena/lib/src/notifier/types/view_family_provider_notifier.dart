part of '../base_notifier.dart';

/// The corresponding notifier of a [ViewFamilyProvider].
final class ViewFamilyProviderNotifier<T, P> extends BaseSyncNotifier<Map<P, T>>
    implements Rebuildable, FamilyNotifier<Map<P, T>, P> {
  late final WatchableRef _watchableRef;
  final ViewFamilyBuilder<T, P> _builder;
  final Map<P, ViewProvider<T>> _providers = {};
  final String Function(T state)? _describeState;
  final _rebuildController = BatchedStreamController<AbstractChangeEvent>();

  ViewFamilyProviderNotifier(
    this._builder, {
    String Function(T state)? describeState,
    super.debugLabel,
  }) : _describeState = describeState;

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
            entry.key: _watchableRef.read(entry.value),
        },
        event,
      );
    });
  }

  @override
  bool isParamInitialized(P param) {
    return state.containsKey(param);
  }

  @override
  void initParam(P param) {
    // create new temporary provider
    final provider = ViewProvider<T>(
      (ref) => _builder(ref, param),
      debugLabel: '$debugLabel($param)',
    );
    _providers[param] = provider;
    _initDependencies(provider);

    _setStateAsRebuild(
      this,
      {
        ...state,
        param: _watchableRef.watch(provider),
      },
      [],
    );
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
    for (final provider in _providers.values) {
      _clearDependencies(provider);
      _container!.internalDispose(provider, this);
    }
    _providers.clear();
    state.clear();
  }

  void _initDependencies(ViewProvider tempProvider) {
    final tempNotifier = _container!.anyNotifier(tempProvider);
    // so this notifier (the family notifier) won't get disposed
    tempNotifier._fakeDependents = true;
    dependencies.add(tempNotifier);
    tempNotifier.dependents.add(this);
  }

  void _clearDependencies(ViewProvider tempProvider) {
    final tempNotifier = _container!.anyNotifier(tempProvider);
    dependencies.remove(tempNotifier);
    tempNotifier.dependents.clear();
  }

  @visibleForTesting
  List<ViewProvider<T>> getTempProviders() {
    return _providers.values.toList();
  }

  @override
  String describeState(Map<P, T> state) {
    if (_describeState != null) {
      return _describeViewMapState(state, _describeState!);
    } else {
      return _describeViewMapState(state, (value) => value.toString());
    }
  }

  @internal
  @override
  void internalSetup(
    ProxyRef ref,
    BaseProvider<BaseNotifier<Map<P, T>>, Map<P, T>>? provider,
  ) {
    _watchableRef = WatchableRefImpl(
      container: ref.container,
      rebuildable: this,
    );

    super.internalSetup(ref, provider);
  }

  @override
  void onDisposeWidget() {}

  @override
  void notifyListenerTarget(BaseNotifier notifier) {}

  @override
  bool get isWidget => false;
}
