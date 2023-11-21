part of '../base_notifier.dart';

/// The corresponding notifier of a [StreamProvider].
final class StreamProviderNotifier<T> extends BaseSyncNotifier<AsyncValue<T>>
    with RebuildableNotifier<AsyncValue<T>, Stream<T>>
    implements GetFutureNotifier<T> {
  StreamProviderNotifier(
    this._builder, {
    String Function(AsyncValue<T> state)? describeState,
    super.debugLabel,
  }) : _describeState = describeState;

  @override
  final Stream<T> Function(WatchableRef ref) _builder;

  final String Function(AsyncValue<T> state)? _describeState;
  final StreamController<T> _streamController = StreamController<T>.broadcast();
  StreamSubscription<T>? _subscription;
  RefDependencyListener<Stream<T>>? _dependencyListener;
  T? _prev;

  @override
  AsyncValue<T> init() {
    _buildStream(
      rebuild: false,
      events: const [],
      debugOrigin: null,
    );
    _rebuildController.stream.listen((event) {
      // rebuild stream
      _buildStream(
        rebuild: true,
        events: event,
        debugOrigin: null,
      );
    });
    return AsyncValue<T>.loading();
  }

  /// Waits for the next value of the stream.
  @override
  Future<T> get future => _streamController.stream.first;

  @nonVirtual
  Stream<T> _buildStream({
    required bool rebuild,
    required List<AbstractChangeEvent> events,
    required LabeledReference? debugOrigin,
  }) {
    _subscription?.cancel(); // ignore: unawaited_futures
    _dependencyListener?.cancel();

    final nextDependencyListener = _callAndListenDependencies();
    _dependencyListener = nextDependencyListener;

    final loadingState = AsyncValue<T>.loading(_prev);
    if (rebuild) {
      _setStateAsRebuild(
        this,
        loadingState,
        events,
        debugOrigin,
      );
    } else {
      _state = loadingState;
    }

    final stream = nextDependencyListener.result;
    _subscription = stream.listen((value) {
      _setState(AsyncValue<T>.data(value), null);
      state = AsyncValue<T>.data(value);
      _streamController.add(value);
      _prev = value;
    }, onError: (error, stackTrace) {
      _setState(AsyncValue<T>.error(error, stackTrace), null);
    });

    return stream;
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

  @override
  Stream<T> rebuildImmediately(LabeledReference debugOrigin) {
    return _buildStream(
      rebuild: true,
      events: const [],
      debugOrigin: debugOrigin,
    );
  }
}
