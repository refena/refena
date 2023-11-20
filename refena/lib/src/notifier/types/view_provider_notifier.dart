part of '../base_notifier.dart';

final class ViewProviderNotifier<T> extends BaseSyncNotifier<T>
    with RebuildableNotifier
    implements Rebuildable {
  ViewProviderNotifier(
    this._builder, {
    String Function(T state)? describeState,
    super.debugLabel,
  }) : _describeState = describeState;

  final T Function(WatchableRef) _builder;
  final String Function(T state)? _describeState;

  @override
  T init() {
    _rebuildController.stream.listen((event) {
      // rebuild notifier state
      _setStateAsRebuild(
        this,
        _callAndSetDependencies(_builder),
        event,
      );
    });
    return _callAndSetDependencies(_builder);
  }

  @override
  String describeState(T state) {
    if (_describeState == null) {
      return super.describeState(state);
    }
    return _describeState!(state);
  }
}
