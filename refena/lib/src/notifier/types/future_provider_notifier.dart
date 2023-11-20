part of '../base_notifier.dart';

/// The corresponding notifier of a [FutureProvider].
final class FutureProviderNotifier<T> extends BaseAsyncNotifier<T>
    with RebuildableNotifier
    implements Rebuildable {
  FutureProviderNotifier(
    this._builder, {
    String Function(AsyncValue<T> state)? describeState,
    super.debugLabel,
  }) : _describeState = describeState;

  final Future<T> Function(WatchableRef ref) _builder;
  final String Function(AsyncValue<T> state)? _describeState;

  @override
  Future<T> init() {
    _rebuildController.stream.listen((event) {
      // rebuild notifier state
      _setFutureAndListenRebuild(event);
    });
    return _callAndTrackNotifiers(_builder);
  }

  /// The rebuild version of [BaseAsyncNotifier._setFutureAndListen].
  @nonVirtual
  void _setFutureAndListenRebuild(List<AbstractChangeEvent> causes) async {
    _future = _callAndTrackNotifiers(_builder);
    _futureCount++;
    final currentCount = _futureCount;
    _setStateAsRebuild(this, AsyncValue<T>.loading(_prev), causes);
    try {
      final value = await _future;
      if (currentCount != _futureCount) {
        // The future has been changed in the meantime.
        return;
      }
      state = AsyncValue.data(value);
      _prev = value; // drop the previous state
    } catch (error, stackTrace) {
      if (currentCount != _futureCount) {
        // The future has been changed in the meantime.
        return;
      }
      state = AsyncValue<T>.error(error, stackTrace, _prev);
    }
  }

  @override
  String describeState(AsyncValue<T> state) {
    if (_describeState == null) {
      return super.describeState(state);
    }
    return _describeState!(state);
  }
}
