part of '../base_notifier.dart';

/// The corresponding notifier of a [StreamProvider].
final class StreamProviderNotifier<T> extends BaseSyncNotifier<AsyncValue<T>>
    with RebuildableNotifier
    implements GetFutureNotifier<T> {
  StreamProviderNotifier(
    this._builder, {
    String Function(AsyncValue<T> state)? describeState,
    super.debugLabel,
  }) : _describeState = describeState;

  final Stream<T> Function(WatchableRef ref) _builder;
  final String Function(AsyncValue<T> state)? _describeState;
  final StreamController<T> _streamController = StreamController<T>.broadcast();
  StreamSubscription<T>? _subscription;
  RefDependencyListener<Stream<T>>? _dependencyListener;
  T? _prev;

  @override
  AsyncValue<T> init() {
    _buildStream();
    _rebuildController.stream.listen((event) {
      // rebuild stream
      _buildStream();
    });
    return AsyncValue<T>.loading();
  }

  /// Waits for the next value of the stream.
  @override
  Future<T> get future => _streamController.stream.first;

  @nonVirtual
  void _buildStream() {
    _subscription?.cancel(); // ignore: unawaited_futures
    _dependencyListener?.cancel();

    final nextDependencyListener = _callAndListenDependencies(_builder);
    _dependencyListener = nextDependencyListener;
    state = AsyncValue<T>.loading(_prev);
    _subscription = nextDependencyListener.result.listen((value) {
      state = AsyncValue<T>.data(value);
      _streamController.add(value);
      _prev = value;
    }, onError: (error, stackTrace) {
      state = AsyncValue<T>.error(error, stackTrace);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _dependencyListener?.cancel();
    _streamController.close();
    super.dispose();
  }

  @override
  String describeState(AsyncValue<T> state) {
    if (_describeState == null) {
      return super.describeState(state);
    }
    return _describeState!(state);
  }
}
