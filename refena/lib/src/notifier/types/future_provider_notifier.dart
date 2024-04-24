part of '../base_notifier.dart';

/// The corresponding notifier of a [FutureProvider].
final class FutureProviderNotifier<T> extends BaseAsyncNotifier<T>
    with RebuildableNotifier<AsyncValue<T>, Future<T>> {
  FutureProviderNotifier(
    this._builder, {
    String Function(AsyncValue<T> state)? describeState,
  }) : _describeState = describeState;

  @override
  final Future<T> Function(WatchableRef ref) _builder;

  final String Function(AsyncValue<T> state)? _describeState;
  RefDependencyListener<Future<T>>? _dependencyListener;

  @override
  Future<T> init() {
    _rebuildController.stream.listen((event) {
      // rebuild future
      _setFutureAndListenRebuild(event, null);
    });
    _dependencyListener = _callAndListenDependencies();
    return _dependencyListener!.result;
  }

  /// The rebuild version of [BaseAsyncNotifier._setFutureAndListen].
  @nonVirtual
  void _setFutureAndListenRebuild(
    List<AbstractChangeEvent> causes,
    LabeledReference? debugOrigin,
  ) async {
    _dependencyListener?.cancel();

    final nextDependencyListener = _callAndListenDependencies();
    _dependencyListener = nextDependencyListener;

    _future = nextDependencyListener.result;
    _futureCount++;
    final currentCount = _futureCount;
    _setStateAsRebuild(this, AsyncValue<T>.loading(_prev), causes, debugOrigin);
    try {
      final value = await _future;
      if (currentCount != _futureCount) {
        // The future has been changed in the meantime.
        return;
      }
      state = AsyncValue.data(value);
      _prev = value; // drop the previous state

      // must not be in finally because of the count check
      _dependencyListener?.cancel();
    } catch (error, stackTrace) {
      if (currentCount != _futureCount) {
        // The future has been changed in the meantime.
        return;
      }
      state = AsyncValue<T>.error(error, stackTrace, _prev);

      // must not be in finally because of the count check
      _dependencyListener?.cancel();
      rethrow;
    }
  }

  @override
  void dispose() {
    _dependencyListener?.cancel();
    super.dispose();
  }

  @override
  String describeState(AsyncValue<T> state) {
    if (_describeState == null) {
      return super.describeState(state);
    }
    return _describeState!(state);
  }

  @override
  Future<T> rebuildImmediately(LabeledReference debugOrigin) async {
    _setFutureAndListenRebuild(const [], debugOrigin);
    return _future;
  }
}
